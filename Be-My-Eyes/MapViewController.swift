//
//  MapViewController.swift
//  Be-My-Eyes
//
//  Created by 박소희 on 2020/07/06.
//  Copyright © 2020 Be-My-Eyes. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation
import Speech
import CoreAudio

var markerList = [MTMapPOIItem] ()
var recognizedLocation = ""

class MapViewController: UIViewController, MTMapViewDelegate, CLLocationManagerDelegate, SFSpeechRecognizerDelegate {

    var mapView: MTMapView?
    var mapPoint: MTMapPoint?
    var mapLine: MTMapPolyline?
    
    ///STT button
    @IBOutlet var speakButton: UIButton!
    ///STT로 입력받은 목적지 정보가 입력될 textview
    @IBOutlet var setDestination: UITextView!
        
    ///STT variables
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        speechRecognizer?.delegate = self
        
        mapView = MTMapView(frame: self.view.bounds)
        // set center point
        mapPoint = MTMapPoint.init(geoCoord: MTMapPointGeo.init(latitude: 37.550950, longitude: 126.941017))
        mapView?.setMapCenter(mapPoint, animated: true)
        
        markerList.append(poiItem(name: "Start", latitude: 37.550950, longitude: 126.941017))
        appendMarkerList()
        
        mapView?.addPOIItems(markerList)
        //mapView?.fitAreaToShowAllPOIItems()
                
        if let mapView = mapView {
            mapView.delegate = self
            mapView.baseMapType = .standard
            mapView.showCurrentLocationMarker = true
            
            //mapView.addCircle(circle())
            mapView.updateCurrentLocationMarker(locationMarker())
            
            self.view.addSubview(mapView)
            self.view.sendSubviewToBack(mapView)
            print("map view")
            
        }
        
    }
    
    @IBAction func onCurrentLocationClick(_ sender: Any) {
        print("current location button")
    }
    
    @IBAction func goToTTS(_ sender: UIButton){
        performSegue(withIdentifier: "unwindToVC1", sender: self)
    }
    
    @IBAction func speechToText(_ sender: Any) {
        if audioEngine.isRunning {              //현재 음성인식이 수행 중인 경우
            audioEngine.stop()                  //audio입력을 중단
            recognitionRequest?.endAudio()      //음성 인식을 중단
            
            speakButton.isEnabled = false
            speakButton.setTitle("SPEAK", for: .normal)
            
            print(recognizedLocation)   //입력받은 목적지 정보 debug
            convertAddrtoCoordinate(address: recognizedLocation)
            
        } else {
            //start recording function
            startRecording()
            speakButton.setTitle("STOP", for: .normal)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // 여기서 map view가 고쳐질 때마다 새로 화면 load
    }
    
    func poiItem(name: String, latitude: Double, longitude: Double) -> MTMapPOIItem {
         let item = MTMapPOIItem()
         item.itemName = name
         item.markerType = .redPin
         item.markerSelectedType = .redPin
         item.mapPoint = MTMapPoint(geoCoord: .init(latitude: latitude, longitude: longitude))
         item.showAnimationType = .noAnimation
         item.customImageAnchorPointOffset = .init(offsetX: 30, offsetY: 0)    // 마커 위치
         
         return item
     }

    func circle() -> MTMapCircle{
        
        let circ = MTMapCircle()
        circ.circleCenterPoint = MTMapPoint(geoCoord: MTMapPointGeo(latitude: 37.550950, longitude: 126.941017))
        
        circ.circleRadius = 50.0
        circ.circleLineColor = UIColor.red
        circ.circleLineWidth = 10
        circ.circleFillColor = UIColor.yellow
        circ.tag = 1
        
        return circ
    }
    func locationMarker() -> MTMapLocationMarkerItem {
        let mark = MTMapLocationMarkerItem()
        
        mark.radius = 30.0
        mark.fillColor = UIColor.blue
        mark.customImageAnchorPointOffset = .init(offsetX: 30, offsetY: 0)
        
        return mark
    }
    func appendMarkerList() {
        markerList.append(poiItem(name: "station", latitude: 37.547674, longitude: 126.9401487))
        markerList.append(poiItem(name: "cafe", latitude: 37.5481577, longitude: 126.9328022))
        markerList.append(poiItem(name: "bank", latitude: 37.5479142, longitude: 126.93233))

    }

    //check if the recognization task is running or not
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        //오디오를 녹음할 AVAudioSession을 생성
        let audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audio session error")
        }
    
        //recognitionRequest를 instance화
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        //audioEngine(device)에 오디오 입력 기능이 작동하는지 확인
        let inputNode = audioEngine.inputNode
//        else {
//            fatalError("Audio engine has no input mode")
//        }
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest obj")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        //audio 인식 시작
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            //인식 결과가 nil이 아니면, textview의 속성을 최상의 텍스트로 설정
            if result != nil{
                self.setDestination.text = result?.bestTranscription.formattedString
                
                //좌표로 변환할, 입력받은 destionation 위치를 저장
                recognizedLocation = self.setDestination.text
                
                isFinal = (result?.isFinal)!
            }
            //오류가 없거나, 최종 결과가 나오면 audioEngine과 인식 작업을 중지
            //녹음 버튼 활성화
            if error != nil || isFinal {
                self.audioEngine.stop()
                
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.speakButton.isEnabled = true
            }
        })
        
        //recognitionRequest에 오디오 입력 추가
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat){ (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do{
            try audioEngine.start()
        } catch {
            print("audio engine start error")
        }
        
        setDestination.text = "목적지를 말해주세요"
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            speakButton.isEnabled = true
        } else {
            speakButton.isEnabled = false
        }
    }
    
    func genertateMapPoint(coordinate: CLLocationCoordinate2D) -> MTMapPoint {
        
        var point = MTMapPoint()
        point = MTMapPoint.init(geoCoord: MTMapPointGeo.init(latitude: coordinate.latitude, longitude: coordinate.longitude))

        return point
    }
    
    func convertAddrtoCoordinate(address: String) {
        
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            if error != nil{
                //NSLog("\(error)")
                return
            }
            guard let placemarks = placemarks,
                let location = placemarks.first?.location else {
                    return
            }
            print(location.coordinate)
            
            //STT로 입력받은 coordinate를 marker list에 추가
            markerList.append(self.poiItem(name: "destination", latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
            self.mapView?.removeAllPOIItems()
            self.mapView?.addPOIItems(markerList)
            self.mapView?.fitAreaToShowAllPOIItems()
            print(markerList)       //debug
            
            let mapPoint2 = self.genertateMapPoint(coordinate: location.coordinate)   //coordinate를 MTMapPoint로 변환
            self.drawPolyLine(point1: self.mapPoint!, point2: mapPoint2)                  //출발지-목적지 간의 polyline 그리기

        }
        
    }
    
    func drawPolyLine(point1: MTMapPoint, point2: MTMapPoint) {
        let line = MTMapPolyline()
        
        line.add(point1)
        //line.add(point2)
        
        var testPoint = MTMapPoint()
        testPoint = MTMapPoint.init(geoCoord: MTMapPointGeo.init(latitude: 37.547674, longitude: 126.9401487))
        line.add(testPoint)
                
        line.polylineColor = UIColor.blue
        line.tag = 2000
        
        self.mapView?.removeAllPolylines()
        self.mapView?.addPolyline(line)
        self.mapView?.fitAreaToShowAllPolylines()
        
        
    }
}

