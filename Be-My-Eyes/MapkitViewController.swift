//
//  MapkitViewController.swift
//  Be-My-Eyes
//
//  Created by hangil lee on 2020/07/15.
//  Copyright © 2020 Kautenja. All rights reserved.
//

import UIKit
import Contacts
import MapKit
import CoreLocation
import AVFoundation
import Speech

class MapkitViewController: UIViewController,  MKMapViewDelegate, CLLocationManagerDelegate, SFSpeechRecognizerDelegate {

    @IBOutlet weak var searchText: UITextField!
    var matchingItems: [MKMapItem] = [MKMapItem]()
    @IBOutlet weak var routeMap: MKMapView!
    
    // TTS
    private var tts: AVSpeechSynthesizer = AVSpeechSynthesizer()
    var islocation = false
    
    //Current Location
    var locationManager: CLLocationManager!
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var travelDistance = 0
    var flag2 = true
    //var response: MKDirections.Response!
    
    //Do
    var step: MKRoute.Step!
    var count = 0
    var flag = true
    var index = 1
    
    //Timer
    var distanceTimer: Timer?
    var directionTimer: Timer?
    
    //Finder
    var flag3 = false
    
    // STT
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var myTextView: UITextField!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ko-KR"))
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @IBAction func STT(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            button.isEnabled = false
            button.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            button.setTitle("Stop Recording", for: .normal)
        }
    }
    func startRecording() {
         
         if recognitionTask != nil {
             recognitionTask?.cancel()
             recognitionTask = nil
         }
         
         let audioSession = AVAudioSession.sharedInstance()
         do {
            try audioSession.setCategory(AVAudioSession.Category.multiRoute)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
         } catch {
             print("audioSession properties weren't set because of an error.")
         }
         
         recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
         
         let inputNode = audioEngine.inputNode
        
         guard let recognitionRequest = recognitionRequest else {
             fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
         }
         
         recognitionRequest.shouldReportPartialResults = true
         
         recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
             
             var isFinal = false
             
             if result != nil {
                 
                 self.myTextView.text = result?.bestTranscription.formattedString
                 isFinal = (result?.isFinal)!
             }
             
             if error != nil || isFinal {
                 self.audioEngine.stop()
                 inputNode.removeTap(onBus: 0)
                 
                 self.recognitionRequest = nil
                 self.recognitionTask = nil
                 
                 self.button.isEnabled = true
             }
         })
         
         let recordingFormat = inputNode.outputFormat(forBus: 0)
         inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
             self.recognitionRequest?.append(buffer)
         }
         
         audioEngine.prepare()
         
         do {
             try audioEngine.start()
         } catch {
             print("audioEngine couldn't start because of an error.")
         }
         
         myTextView.text = "Say something, I'm listening!"
         
     }
     
     
    
     func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
         if available {
             button.isEnabled = true
         } else {
             button.isEnabled = false
         }
     }
    // Go Back to main menu
    @IBAction func GoBack(_ sender: Any) {
        distanceTimer!.invalidate()
        directionTimer!.invalidate()
        dismiss(animated: true, completion: nil)
        
    }
    
    // Find the way
    @IBAction func Find(_ sender: Any) {
        flag3 = true
        flag2 = true
        self.getDirections()
    }
    
    // Search
    @IBAction func FindDirection(_ sender: Any) {
        resignFirstResponder()
        //mapView.removeAnnotation(mapView.annotations as! MKAnnotation)
        self.performSearch()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        routeMap.delegate = self
        routeMap.userTrackingMode = .follow
        
        distanceTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(MapkitViewController.distanceCheck), userInfo: nil, repeats: true)
        directionTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(MapkitViewController.getDirections), userInfo: nil, repeats: true)
        
        speechRecognizer?.delegate = self
    }
    
    // mapView
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        mapView.centerCoordinate = userLocation.location!.coordinate
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        return renderer
    }
    
    // TTS
    func speak(_ string: String) {
        if islocation == false {
            let utterance = AVSpeechUtterance(string: string)
            utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
            utterance.rate = 0.5
            tts.speak(utterance)
        }
    }
    
    // LocationManager
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if flag2 == true{
            startLocation = locationManager.location
            flag2 = false
        }
        else{
            lastLocation = locationManager.location
            travelDistance = Int(startLocation.distance(from: lastLocation))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code == .denied{
            manager.stopUpdatingLocation()
            manager.stopMonitoringSignificantLocationChanges()
        }
    }
    
    // Search
    func performSearch() {
        // 배열 값 삭제
        matchingItems.removeAll()
        let request = MKLocalSearch.Request()
        // 텍스트 필드의 값으로 초기화된 MKLocalSearchRequest 인스턴스를 생성
        request.naturalLanguageQuery = searchText.text
        // 검색 요청 인스턴스에 대한 참조체로 초기화
        let search = MKLocalSearch(request: request)
        // MKLocalSearchCompletionHandler 메서드가 호출되면서 검색이 시작
        search.start(completionHandler: {(response: MKLocalSearch.Response!, error: Error!) in
            if error != nil {
                print("Error occured in search: \(error.localizedDescription)")
            } else if response.mapItems.count == 0 {
                print("No matches found")
            } else {
                print("Matches found")
                // 일치된 값이 있다면 일치된 위치에 대한 mapItem 인스턴스의 배열을 가지고 mapItem 속성에 접근한다.
                for item in response.mapItems as [MKMapItem] {
                    if item.name != nil {
                        print("Name = \(item.name!)")
                    }
                    if item.phoneNumber != nil {
                        print("Phone = \(item.phoneNumber!)")
                    }
                    
                    self.matchingItems.append(item as MKMapItem)
                    print("Matching items = \(self.matchingItems.count)")
                    // 맵에 표시할 어노테이션 생성
                }
            }
        })
    }
    
    // Find the way
    @objc func getDirections() {
        if flag3 == true{
            let request = MKDirections.Request()
            request.source = MKMapItem.forCurrentLocation()
            request.destination = matchingItems[0]
            request.requestsAlternateRoutes = false
            request.transportType = .walking
            
            let directions = MKDirections(request: request)
            
            directions.calculate(completionHandler: {( response: MKDirections.Response!, error: Error!) in
                if error != nil {
                    print("Error getting directions")
                } else {
                    self.showRoute(response: response)
                }
            })
        }
    }
    
    // Draw the route and speak the way to user
    func showRoute(response: MKDirections.Response) {
        // MKRoute 객체들을 반복해서 가져와서 맵 뷰의 레이어로 polyline을 추가한다.
        for route in response.routes as [MKRoute] {
            routeMap.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
            // 턴바이턴 경로 출력(경로의 각 구간에 대한 텍스트 안내)

            if flag == true{
                for _ in route.steps{
                    count += 1
                    flag = false
                    step = route.steps[index]
                }
            }
            else{
                if index < count{
                    print("\(Int(step.distance)) vs \(Int(travelDistance))")
                    if Int(travelDistance) > Int(step.distance)  {
                        if step.instructions.contains("우회전") {
                            speak("우회전 하세요.")
                            print(step.instructions)
                        }
                        else if step.instructions.contains("좌회전"){
                            speak("좌회전 하세요")
                            print(step.instructions)
                        }
                        else{
                            speak(step.instructions)
                            print(step.instructions)
                        }
                        travelDistance = 0
                        index += 1
                        if index == count{
                            distanceTimer!.invalidate()
                            directionTimer!.invalidate()
                            break
                        }
                        step = route.steps[index]
                        
                        flag2 = true
                        startLocation = nil
                        lastLocation = nil
                        
                    }
                }
            }
        }
        let userLocation = routeMap.userLocation
        let region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        
        routeMap.setRegion(region, animated: true)
    }
    
    // Find user location
    @objc func distanceCheck (){
        if flag3 == true {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.distanceFilter = 10
        }
    }
}
