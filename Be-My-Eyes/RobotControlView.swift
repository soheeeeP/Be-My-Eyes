//
//  RobotControlView.swift
//  Be-My-Eyes
//
//  Created by 방윤 on 2020/07/07.
//  Copyright © 2020 Be-My-Eyes. All rights reserved.
//

import UIKit
import CocoaMQTT

class RobotControlView: UIViewController {

    var stop = "stop"
    var direction: [Int: String] = [0: "Go straight.",
                                    1: "It's blocked. Go back.",
                                    2: "Move left.",
                                    3: "Move right."]
    

    let mqttClient = CocoaMQTT(clientID: "BME_ROBOT", host:"192.168.137.118", port:1883)

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func buttonDown(_ sender: UIButton) {
        print("Sending message: \(direction[sender.tag]!)")
        //mqttClient.publish("robot/move", withString: direction[sender.tag]!)
    }
    @IBAction func buttonUp(_ sender: UIButton) {
        print("Sending message: \(stop)")
        //mqttClient.publish("robot/move", withString: stop)
    }
    @IBAction func connectButtonPressed(_ sender: UIButton) {
        //mqttClient.connect()
    }
}
