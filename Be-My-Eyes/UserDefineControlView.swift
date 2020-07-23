//
//  UserDefineControlView.swift
//  Be-My-Eyes
//
//  Created by 방윤 on 2020/07/23.
//  Copyright © 2020 Be-My-Eyes. All rights reserved.
//

import UIKit

var userStride = ""
var isUser = false

class UserDefineControlView: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /* Initialize keyboard */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.becomeFirstResponder()
    }
    
    @IBAction func cancel() {
        print("Contents of the text field: \(textField.text!)")
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func done() {
        print("Contents of the text field: \(textField.text!)")
        navigationController?.popViewController(animated: true)
        userStride = textField.text!
        isUser = true
        print(userStride)
    }
}
