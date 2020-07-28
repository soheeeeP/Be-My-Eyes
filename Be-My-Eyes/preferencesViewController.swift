//
//  preferencesViewController.swift
//  Be-My-Eyes
//
//  Created by 박소희 on 2020/07/28.
//  Copyright © 2020 Kautenja. All rights reserved.
//

import UIKit

class preferencesViewController: UIViewController {

    @IBOutlet weak var userName: UITextField!
    
    /// preferences info
    @IBOutlet weak var RealTimeLocation: UISwitch!
    @IBOutlet weak var userStride: UITextField!
    @IBOutlet weak var addrLatitude: UITextField!
    @IBOutlet weak var addrLongitude: UITextField!
    
    @IBOutlet weak var saveButton: UIButton!
    
    
    var isAuto : Bool! = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        designButton()
        
        setState()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // auto save mode
    @IBAction func autoSaveAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected == true {
            isAuto = true
        } else {
            isAuto = false
        }
    }

    // save preferences info for once
    @IBAction func saveUserInfo(_ sender: UIButton) {
        
        let userDefaults = UserDefaults.standard

        //auto load
        if isAuto == true {
            userDefaults.set(userName.text, forKey: "name")
            userDefaults.set(RealTimeLocation.isOn,forKey: "realtime")
            userDefaults.set(userStride.text,forKey: "stride")
            userDefaults.set(addrLatitude.text,forKey: "lat")
            userDefaults.set(addrLongitude.text, forKey: "long")
            userDefaults.synchronize()
        }
        
    }
    
    func designButton(){
        saveButton.layer.cornerRadius = 10
        saveButton.layer.shadowColor = UIColor.gray.cgColor
        saveButton.layer.shadowOpacity = 1.0
        saveButton.layer.shadowOffset = CGSize.zero
        saveButton.layer.shadowRadius = 6
    }
    
    func defaultState(){
        // default setting
        RealTimeLocation.isOn = true
        userStride.text = "35"
        addrLatitude.text = "37.550950"
        addrLongitude.text = "126.941017"
        userName.text = "user"
    }
    
    func setState(){
        let userDefaults = UserDefaults.standard
        
        if let realTime = userDefaults.value(forKey: "realtime"),
            let stride = userDefaults.value(forKey: "stride"),
            let latitude = userDefaults.value(forKey: "lat"),
            let longitude = userDefaults.value(forKey: "long"),
            let name = userDefaults.value(forKey: "name"){
            
            // load auto saved info
            RealTimeLocation.isOn = realTime as! Bool
            userStride.text = stride as? String
            addrLatitude.text = latitude as? String
            addrLongitude.text = longitude as? String
            userName.text = name as? String
            
        } else {
            defaultState()
        }
        saveButton.sendActions(for: .touchUpOutside)

//        let webPage = self.storyboard?.instantiateViewController(withIdentifier: "segmentationView")
//        self.present(webPage!, animated: true, completion: nil)
    
//        performSegue(withIdentifier: "seguetoMainView", sender: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
