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

class UserDefineControlView: UIViewController, UINavigationControllerDelegate, UINavigationBarDelegate {
    
    @IBOutlet weak var SaveLocation: UISwitch!
    @IBOutlet weak var UserID: UITextField!
    @IBOutlet weak var UserStride: UITextField!

    @IBOutlet weak var HomeLatitude: UITextField!
    @IBOutlet weak var HomeLongitude: UITextField!
    
    @IBOutlet weak var autoSave: UIButton!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    var isAuto: Bool! = true
    var state: Bool! = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.delegate = self

        autoSave.isSelected = true
        if let name = UserDefaults.standard.string(forKey: "name") {
            print("username: " + name)
        }
        
        state = setState()
    }
    
    /* Initialize keyboard */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UserStride.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //앱을 켰을 때, 사용자 정보가 저장되어 있는 경우(초기화면), 바로 mainview를 호출
        if state == true && resetPreferences == false {
            callingMainView()
//            UIApplication.shared.sendAction(saveButton
//                .action!, to: saveButton.target, from: self, for: nil)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func autoSaveAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected == true {
            isAuto = true
        } else {
            isAuto = false
        }
    }
    /// Go back to Main view without saving the preferences info
    @IBAction func cancel(_ sender: UIStoryboardSegue) {
        self.dismiss(animated: true, completion: nil)
    }

    /// Save the Preferences and Go back to Main View
    @IBAction func done(_ sender: UIStoryboardSegue) {
        let userDefaults = UserDefaults.standard
                
        //if autoSave mode is on, save the preferences info
        if isAuto == true {
            userDefaults.set(UserID.text, forKey: "name")
            userDefaults.set(SaveLocation.isOn, forKey: "realtime")
            userDefaults.set(UserStride.text, forKey: "stride")
            userDefaults.set(HomeLatitude.text, forKey: "lat")
            userDefaults.set(HomeLongitude.text, forKey: "long")
            userDefaults.synchronize()
        }


        print("Contents of the text field: \(UserStride.text!)")
        userID = UserID.text!
        userStride = UserStride.text!
        homeLatitude = HomeLatitude.text!
        homeLongitude = HomeLongitude.text!
                
        isUser = true
        Firecount = 0
        
        resetPreferences = false
        
        //앱을 처음 실행하는 경우(사용자 정보가 저장되어 있지 않은 상태) mainview를 호출
        if state == false {
            callingMainView()
        }
        //앱 사용 중에 사용자 정보를 변경하는 경우, preference view를 dismiss시켜서 직전의 mainview로 되돌아감
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    /// 사용자가 위치 추적 여부를 선택
    @IBAction func actionTriggered(_ sender: Any) {
        if SaveLocation.isOn {
            saveLocation = true
            print("Save Real-Time Location Mode On")
        }
        else {
            saveLocation = false
            print("Save Real-Time Location Mode Off")
        }
    }
    
    func callingMainView() {
        guard let uvc = self.storyboard?.instantiateViewController(withIdentifier: "MainView") else {
                    return
                }
        uvc.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        self.present(uvc, animated: true)
    }
    
    func defaultState(){
        // default setting
        SaveLocation.isOn = true
        UserStride.text = "35"
        HomeLatitude.text = "37.550950"
        HomeLongitude.text = "126.941017"
        UserID.text = "user"
    }
    
    func setState() -> Bool {
        let userDefaults = UserDefaults.standard
        
        if let realTime = userDefaults.value(forKey: "realtime"),
            let stride = userDefaults.string(forKey: "stride"),
            let latitude = userDefaults.string(forKey: "lat"),
            let longitude = userDefaults.string(forKey: "long"),
            let name = userDefaults.string(forKey: "name"){
            
            // load auto saved info
            SaveLocation.isOn = realTime as! Bool
            UserStride.text = stride
            HomeLatitude.text = latitude
            HomeLongitude.text = longitude
            UserID.text = name
            
            print("load auto save info")
            return true
            
        } else {
//            defaultState()
            
            print("default mode")
            return false
        }
    }
}
