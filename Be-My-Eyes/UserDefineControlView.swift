//
//  UserDefineControlView.swift
//  Be-My-Eyes
//
//  Created by 방윤 on 2020/07/23.
//  Copyright © 2020 Be-My-Eyes. All rights reserved.
//

import UIKit

var saveLocation = false
var userID = ""
var userStride = ""
var homeLatitude = ""
var homeLongitude = ""
var isUser = false

class UserDefineControlView: UIViewController {
    
    @IBOutlet weak var SaveLocation: UISwitch!
    @IBOutlet weak var UserID: UITextField!
    @IBOutlet weak var UserStride: UITextField!

    @IBOutlet weak var HomeLatitude: UITextField!
    @IBOutlet weak var HomeLongitude: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /* Initialize keyboard */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UserStride.becomeFirstResponder()
    }
    
    @IBAction func cancel() {
        print("Contents of the text field: \(UserStride.text!)")
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func done() {
        print("Contents of the text field: \(UserStride.text!)")
        navigationController?.popViewController(animated: true)
        userID = UserID.text!
        userStride = UserStride.text!
        homeLatitude = HomeLatitude.text!
        homeLongitude = HomeLongitude.text!
        
        isUser = true
        print(userID)
        print(userStride)
        print(homeLatitude)
        print(homeLongitude)
    }
    
    /// 사용자가 위치 추적 여부를 선택
    @IBAction func actionTriggered(_ sender: Any) {
        let onState = SaveLocation.isOn
        
        if onState {
            saveLocation = true
            print("Save Location O")
        }
        else {
            saveLocation = false
            print("Save Location X")
        }
    }
}
