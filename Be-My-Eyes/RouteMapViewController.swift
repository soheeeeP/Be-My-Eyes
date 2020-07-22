//
//  RouteMapViewController.swift
//  Be-My-Eyes
//
//  Created by hangil lee on 2020/07/22.
//  Copyright © 2020 Kautenja. All rights reserved.
//

import UIKit
import MapKit
import AVFoundation
import CoreLocation

class RouteMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    // Implement TTS
     private var tts: AVSpeechSynthesizer = AVSpeechSynthesizer()
     var islocation = false
     
     var destination: MKMapItem?
     @IBOutlet weak var routeMap: MKMapView!
     
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
     
    @IBAction func GoBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
         super.viewDidLoad()
         
        // distanceTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(RouteMapViewController.distanceCheck), userInfo: nil, repeats: true)
         //directionTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(RouteMapViewController.getDirections), userInfo: nil, repeats: true)
         // 사용자 정의 메서드
         // 이 클래스가 맵 뷰에 대한 델리게이트로 설정
         //show2.text = "\(flag2)"
         locationManager = CLLocationManager()
         locationManager.delegate = self
         locationManager.requestWhenInUseAuthorization()
         locationManager.desiredAccuracy = kCLLocationAccuracyBest
         locationManager.startUpdatingLocation()
         locationManager.startMonitoringSignificantLocationChanges()
         locationManager.distanceFilter = 10
         
         routeMap.delegate = self
         routeMap.userTrackingMode = .follow
         
         //self.getDirections()
         // Do any additional setup after loading the view.
     }

     @objc func getDirections() {
         let request = MKDirections.Request()
         request.source = MKMapItem.forCurrentLocation()
         request.destination = destination!
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
     
     func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
         let renderer = MKPolylineRenderer(overlay: overlay)
         
         renderer.strokeColor = UIColor.blue
         renderer.lineWidth = 5.0
         return renderer
     }
     
     func speak(_ string: String) {
         if islocation == false {
             let utterance = AVSpeechUtterance(string: string)
             utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
             utterance.rate = 0.5
             tts.speak(utterance)
         }
     }
     
     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
         if flag2 == true{
             startLocation = locationManager.location
             flag2 = false
         }
         else{
             lastLocation = locationManager.location
             travelDistance = Int(startLocation.distance(from: lastLocation))
         }
         print("\(startLocation)")
         print("\(lastLocation)")
     }
     
     func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
         if (error as? CLError)?.code == .denied{
             manager.stopUpdatingLocation()
             manager.stopMonitoringSignificantLocationChanges()
         }
     }
     
     @objc func distanceCheck (){
         locationManager = CLLocationManager()
         locationManager.delegate = self
         locationManager.requestWhenInUseAuthorization()
         locationManager.desiredAccuracy = kCLLocationAccuracyBest
         locationManager.startUpdatingLocation()
         locationManager.startMonitoringSignificantLocationChanges()
         locationManager.distanceFilter = 10
     }
     
}
