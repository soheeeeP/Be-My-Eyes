//
//  StartViewController.swift
//  Be-My-Eyes
//
//  Created by MAC09 on 2020/05/26.
//  Copyright © 2020 Kautenja. All rights reserved.
//

import UIKit
import AVFoundation

class StartViewController: UIViewController{
    // Implement TTS
    private var tts: AVSpeechSynthesizer = AVSpeechSynthesizer()

    
    //Swipe left -> Close app
    @IBAction func Swipe(_ sender: Any) {
        print("Left")
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    }
    

    @IBAction func swipeToPreferences(_ sender: Any) {
        
    }
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
        speak("Swipe the app to the left if you want to start it, or to the right if you want to close it.")
        speak("Tap once to find out where you are.")
        // Do any additional setup after loading the view.
    }
    
    
    // Implement TTS
    func speak(_ string: String) {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        tts.speak(utterance)
    }
    

}
