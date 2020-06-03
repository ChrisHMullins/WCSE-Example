//
//  ViewController.swift
//  WCSE
//
//  Created by Christopher Mullins on 5/21/20.
//  Copyright © 2020 Christopher Mullins. All rights reserved.
//

import UIKit
import WatchConnectivity
import HealthKit

class ViewController: UIViewController, WCSessionDelegate {

    
    @IBOutlet weak var counterLabel: UILabel!
    
    @IBAction func buttonPress(_ sender: Any) {
        print("send message to watch")
        sendWatchMessage() // This should make the watch vibrate.
    }
    
    @IBOutlet weak var heartRateLabel: UILabel!
    
    var lastMessage: CFAbsoluteTime = 0
    var counter: Int = 0
    
    private var healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

        self.counterLabel.text = "Count: \(counter)"
    }
    
    func sendWatchMessage() {
        let currentTime = CFAbsoluteTimeGetCurrent()

        // Throttle - if less than half a second has passed, bail out.
        if lastMessage + 0.5 > currentTime {
            return
        }

        // send a message to the watch if it's reachable
        if (WCSession.default.isReachable) {
            // this is a meaningless message, but it's enough for our purposes
            let message = ["Message": "Hello"]
            WCSession.default.sendMessage(message, replyHandler: nil)
        }

        // update our rate limiting property
        lastMessage = CFAbsoluteTimeGetCurrent()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {

    }

    func sessionDidBecomeInactive(_ session: WCSession) {

    }

    func sessionDidDeactivate(_ session: WCSession) {

    }

    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        DispatchQueue.main.async {
            print("Message recieved...")
            
            if let heartRate = message["heartRate"] {
                
                print("Heart Rate: \(heartRate)")
                
                // Not sure why this is coming back wrong.
                // Am I sending too fast from the watch? Uncomment print above to see it come across.
                self.heartRateLabel.text = "BPM: \(heartRate)"
                //
                //
                
            } else if message["click"] != nil {
                //print("click")
                self.counter += 1
                self.counterLabel.text = "Count: \(self.counter)"
            } else {
                self.heartRateLabel.text = "BPM: --"
                //print("no message")
            }
        }
    }
    
}

