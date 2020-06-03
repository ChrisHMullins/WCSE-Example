//
//  InterfaceController.swift
//  WCSE WatchKit Extension
//
//  Created by Christopher Mullins on 5/21/20.
//  Copyright © 2020 Christopher Mullins. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import HealthKit

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    @IBAction func buttonPress() {
        sendMessage()
    }
    
    private var healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")
    var heartRateValue = 0
    
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    override func willActivate() {
        super.willActivate()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        autorizeHealthKit()
        startHeartRateQuery(quantityTypeIdentifier: .heartRate)
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {

    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // This does a haptic buzz on the watch. It is super faint so you may want to change your watch settings to make it stronger.
        // Seriously, you may not even feel it and think it's not working.
        WKInterfaceDevice().play(.click)
    }

    func autorizeHealthKit() {
        let healthKitTypes: Set = [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]

        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in }
    }
    
    func sendMessage() {
        // This should increment a value on the phone.
        // This won't make it through if sending heart rate data because the heart rate data is saturating??
        //
        // send a message to the Phone if it's reachable
        if (WCSession.default.isReachable) {
            let message = ["click": "increment value"]
            WCSession.default.sendMessage(message, replyHandler: nil)
        } else {
            print("Phone was not reachable?")
        }
    }
    
    func sendHeartRateMessage() {
        // This sends a heart rate value
        // send a message to the Phone if it's reachable
        if (WCSession.default.isReachable) {
            let message = ["heartRate": heartRateValue]
            WCSession.default.sendMessage(message, replyHandler: nil)
        } else {
            print("Phone was not reachable?")
        }
    }
    
    private func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {

        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            
            self.process(samples, type: quantityTypeIdentifier)
        }
        
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!, predicate: devicePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        
        query.updateHandler = updateHandler
        
        healthStore.execute(query)
    }
    
    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        var lastHeartRate = 0.0
        
        for sample in samples {
            if type == .heartRate {
                lastHeartRate = sample.quantity.doubleValue(for: heartRateQuantity)
                
                print("value set...") // You have to switch to this process to see messages. Might not show on actual watch.
                self.heartRateValue = Int(lastHeartRate)
                self.heartRateLabel.setText("BPM: \(heartRateValue)")
                
                //sendHeartRateMessage() // Comment this out if you want to send messages with the button.
            }
            
        }
    }
    
}
