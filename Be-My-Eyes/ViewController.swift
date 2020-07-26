//
//  ViewController.swift
//  Be-My-Eyes
//
//  Created by Be-My-Eyes on 04/28/20.
//  Copyright © 2020 Be-My-Eyes. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import Metal
import MetalPerformanceShaders
import CoreMotion
import CoreLocation
import Firebase

// 사용자의 이동 경로를 저장할 배열
var visitedLocationInfo : [String] = []
var Firecount = 0

/// A view controller to pass camera inputs through a vision model
class ViewController: UIViewController, CLLocationManagerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate{
    /// a local reference to time to update the framerate
    var time = Date()
    
    var ready = true
    var islocation = false

    /// the view to preview raw RGB data from the camera
    @IBOutlet weak var preview: UIView!
    /// the view for showing the segmentation
    @IBOutlet weak var segmentation: UIImageView!
    /// a label to show the framerate of the model
    @IBOutlet weak var framerate: UILabel!
    /// a text that will be changed to speech
    @IBOutlet weak var textforspeech: UILabel!
    
    @IBOutlet weak var depthPreview: UIImageView!
    
    let depthSession = AVCaptureSession()
    let dataOutputQueue = DispatchQueue(label: "video data queue",
                                        qos: .userInitiated,
                                        attributes: [],
                                        autoreleaseFrequency: .workItem)

    var depthMap: CIImage?
    var scale: CGFloat = 0.0
    
    /// the camera session for streaming data from the camera
    var captureSession: AVCaptureSession!
    /// the video preview layer
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    // Implement TTS
    private var tts: AVSpeechSynthesizer = AVSpeechSynthesizer()
    private var lastPredictionTime: Double = 0.0
    private let PredictionInterval: TimeInterval = 5.0
    
    //Check Horzion
    private var motionManager: CMMotionManager?
    private var isFacingHorzion: Bool = false
    private let GravityCheckInterval: TimeInterval = 1.0
    
    //Current Location
    var locationManager: CLLocationManager!
    var administrativeArea = ""
    var locality = ""
    var thoroughfare = ""
    var subLocality = ""
    var CurrentLocation = ""
    var Count = 0
    var Check = 0
    
    //Saving Real-Time Location
    private var lastSavedTime: Double = 0.0
    private let savingLocationInterval: TimeInterval = 10.0
    
    /// TODO:
    private var _device: MTLDevice?
    /// TODO:
    var device: MTLDevice! {
        get {
            // try to unwrap the private device instance
            if let device = _device {
                return device
            }
            _device = MTLCreateSystemDefaultDevice()
            return _device
        }
    }
    var _queue: MTLCommandQueue?
    
    @IBAction func asdasd(_ sender: Any) {
        Count = 0
        locationModeOn()
        
//        locationManager = CLLocationManager()
//        locationManager.delegate = self
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.startUpdatingLocation()
    }
    var queue: MTLCommandQueue! {
        get {
            // try to unwrap the private queue instance
            if let queue = _queue {
                return queue
            }
            _queue = device.makeCommandQueue()
            return _queue
        }
    }
    @IBAction func wind(_ sender: Any) {
        self.performSegue(withIdentifier: "ManualWind", sender: self)
    }
    
    @IBAction func unwindToVC(_ sender: UIStoryboardSegue) {
    }
    /// the model for the view controller to apss camera data through
    private var _model: VNCoreMLModel?
    /// the model for the view controller to apss camera data through
    var model: VNCoreMLModel! {
        get {
            // try to unwrap the private model instance
            if let model = _model {
                return model
            }
            
            do {
                _model = try VNCoreMLModel(for: Tiramisu45().model)
            } catch let error {
                let message = "failed to load model: \(error.localizedDescription)"
                popup_alert(self, title: "Model Error", message: message)
            }
            return _model
        }
    }
    
    /// the request and handler for the model
    private var _request: VNCoreMLRequest?
    /// the request and handler for the model
    var request: VNCoreMLRequest! {
        
        get {
            // try to unwrap the private request instance
            if let request = _request {
                return request
            }
            // create the request
            _request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
                // handle an error from the inference engine
                if let error = error {
                    print("inference error: \(error.localizedDescription)")
                    return
                }
                
                // make sure the UI is ready for another frame
                guard self.ready else { return }
                
                // get the outputs from the model
                let outputs = finishedRequest.results as? [VNCoreMLFeatureValueObservation]
                // get the probabilities as the first output of the model
                guard let softmax = outputs?[0].featureValue.multiArrayValue else {
                    print("failed to extract output from model")
                    return
                }
                // get the dimensions of the probability tensor
                let channels = softmax.shape[0].intValue
                let height = softmax.shape[1].intValue
                let width = softmax.shape[2].intValue
                                
                // create an image for the softmax outputs
                let desc = MPSImageDescriptor(channelFormat: .float32,
                                              width: width,
                                              height: height,
                                              featureChannels: channels)
                let probs = MPSImage(device: self.device, imageDescriptor: desc)
                probs.writeBytes(softmax.dataPointer,
                                 dataLayout: .featureChannelsxHeightxWidth,
                                 imageIndex: 0)
                
                // create an output image for the Arg Max output
                let desc1 = MPSImageDescriptor(channelFormat: .float32,
                                               width: width,
                                               height: height,
                                               featureChannels: 1)
                let classes = MPSImage(device: self.device, imageDescriptor: desc1)

                // create a buffer and pass the inputs through the filter to the outputs
                let buffer = self.queue.makeCommandBuffer()
                let filter = MPSNNReduceFeatureChannelsArgumentMax(device: self.device)
                filter.encode(commandBuffer: buffer!, sourceImage: probs, destinationImage: classes)

                // add a callback to handle the buffer's completion and commit the buffer
                buffer?.addCompletedHandler({ (_buffer) in
                    let argmax = try! MLMultiArray(shape: [1, softmax.shape[1], softmax.shape[2]], dataType: .float32)
                    classes.readBytes(argmax.dataPointer,
                                      dataLayout: .featureChannelsxHeightxWidth,
                                      imageIndex: 0)
    
                    // unmap the discrete segmentation to RGB pixels
                    let image = codesToImage(argmax)
                    // update the image on the UI thread
                    DispatchQueue.main.async {
                        self.segmentation.image = image
                        let fps = -1 / self.time.timeIntervalSinceNow
                        self.time = Date()
                        self.framerate.text = "\(fps)"
                        self.textforspeech.text = "\(FindObject(argmax))"
                        
                        if self.handlePrediction() == 0{
                            self.speak("\(FindObject(argmax))")
                        }
                        else {
                            if (obstacleFlag && idxAppeared[obstacle_idx] == 0){
                                idxAppeared[obstacle_idx] = 1
                                print(obstacle)
                                if obstacleDistance == 0 {
                                    self.speak("\(obstacle) is in front of you.")
                                }
                                else {
                                    self.speak("\(obstacle) is \(obstacleDistance) steps ahead.")
                                }
                                obstacleFlag = false
                                obstacleDistance = 0
                            }
                        }
                        
                        self.savingLocation()
                    }
                    self.ready = true
                })
                self.ready = false
                buffer?.commit()
            }
            // set the input image size to be a scaled version of the image
            _request?.imageCropAndScaleOption = .scaleFill //centerCrop scaleFill scaleFit
            return _request

        }
    }
  
    /// Respond to a memory warning from the OS
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        popup_alert(self, title: "Memory Warning", message: "received memory warning")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCaptureSession()
        depthSession.startRunning()
    }
    
    /// Handle the view appearing
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // setup the AV session
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1280x720
        // get a handle on the back camera
        guard let camera = AVCaptureDevice.default(for: AVMediaType.video) else {
            let message = "Unable to access the back camera!"
            popup_alert(self, title: "Camera Error", message: message)
            return
        }
        if Check == 0{
            locationModeOn()
//            locationManager = CLLocationManager()
//            locationManager.delegate = self
//            locationManager.requestWhenInUseAuthorization()
//            locationManager.desiredAccuracy = kCLLocationAccuracyBest
//            locationManager.startUpdatingLocation()
            Check = 1
        }
        // create an input device from the back camera and handle
        // any errors (i.e., privacy request denied)
        do {
            // setup the camera input and video output
            let input = try AVCaptureDeviceInput(device: camera)
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            // add the inputs and ouptuts to the sessionr and start the preview
            if captureSession.canAddInput(input) && captureSession.canAddOutput(videoOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(videoOutput)
                setupCameraPreview()
            }
        }
        catch let error  {
            let message = "failed to intialize camera: \(error.localizedDescription)"
            popup_alert(self, title: "Camera Error", message: message)
            return
        }
//        configureCaptureSession()
//        depthSession.startRunning()
        
    }
          
    /// Setup the live preview from the camera
    func setupCameraPreview() {
        // create a video preview layer for the view controller
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        // set the metadata of the video preview
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.connection?.videoOrientation = .landscapeRight //==.portrait
        // add the preview layer as a sublayer of the preview view
        preview.layer.addSublayer(videoPreviewLayer)
        // start the capture session asyncrhonously
        DispatchQueue.global(qos: .userInitiated).async {
            // start the capture session in the background thread
            self.captureSession.startRunning()
            // set the frame of the video preview to the bounds of the
            // preview view
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.preview.bounds
            }
        }
        // A function that verifies that the camera is vertical.
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = TimeInterval(GravityCheckInterval)
        
        if let queue = OperationQueue.current {
            motionManager!.startDeviceMotionUpdates(to: queue, withHandler: { motionData, error in
                self.handleGravity(motionData!.gravity)
            })
        }
    }
    
    /// Handle a frame from the camera video stream
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // create a Core Video pixel buffer which is an image buffer that holds pixels in main memory
        // Applications generating frames, compressing or decompressing video, or using Core Image
        // can all make use of Core Video pixel buffers
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            let message = "failed to create pixel buffer from video input"
            popup_alert(self, title: "Inference Error", message: message)
            return
        }
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let previewImage = depthMap ?? image
        
        let displayImage = UIImage(ciImage: previewImage)
        
        DispatchQueue.main.sync { [weak self] in
            self?.depthPreview.image = displayImage
        }

        // execute the request
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        } catch let error {
            let message = "failed to perform inference: \(error.localizedDescription)"
            popup_alert(self, title: "Inference Error", message: message)
        }
    }

    
    // Implement TTS
    func speak(_ string: String) {
        if islocation == false {
            let utterance = AVSpeechUtterance(string: string)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5
            tts.speak(utterance)
        }
    }
    
    func speak2(_ string: String) {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        utterance.rate = 0.5
        tts.speak(utterance)
        islocation = false
    }
    
    // Check camera horizon
    func handleGravity(_ gravity: CMAcceleration) {
        isFacingHorzion = gravity.x <= -0.8 && gravity.x <= 1.0
        if (!isFacingHorzion) {
            // TODO: Make some beep for this
            speak("Make sure the camera is vertical.")
        }
    }
    func handlePrediction() -> Int{
        if (!isFacingHorzion) {
            return -1
        }
        let currentTime = Date().timeIntervalSince1970
        
        if (lastPredictionTime == 0 || (currentTime - lastPredictionTime) > PredictionInterval) {
            // Clear tts queue
            tts.stopSpeaking(at: .word)
            idxAppeared = Array(repeating: 0, count: 12)  //initialize appeard obstacle per 10 sec
            lastPredictionTime = Date().timeIntervalSince1970
            return 0
        }
        else{
            return -1
        }
    }
    
    func locationModeOn() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
    }
    func getCurrentCoordinate() -> CLLocation{
        let coordinate = locationManager.location?.coordinate
        let findLocation = CLLocation(latitude: coordinate!.latitude, longitude: coordinate!.longitude)
        
        return findLocation
        
    }
    func getCurrentGeolocation(currentCLLocation: CLLocation) -> String {
        
        var currentGeoLocation = ""
        let geocoder = CLGeocoder()
        let locale = Locale(identifier: "Ko-kr") //원하는 언어의 나라 코드를 넣어주시면 됩니다.
        
        geocoder.reverseGeocodeLocation(currentCLLocation, preferredLocale: locale, completionHandler: {(placemarks, error) in
            if let address: [CLPlacemark] = placemarks {
                if let administrativeArea: String = address.last?.administrativeArea { self.administrativeArea = administrativeArea }
                if let locality: String = address.last?.locality { self.locality = locality }
                if let thoroughfare: String = address.last?.thoroughfare { self.thoroughfare = thoroughfare }
                if let subLocality: String = address.last?.subLocality { self.subLocality = subLocality }
            }
        })

        currentGeoLocation = administrativeArea + " " + locality + " " + thoroughfare
        
        return currentGeoLocation
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        //print("locations = \(locValue.latitude) \(locValue.longitude)")
        
        let findLocation = CLLocation(latitude: locValue.latitude, longitude: locValue.longitude)
        CurrentLocation = getCurrentGeolocation(currentCLLocation: findLocation)

        if Count == 0{
            Count += 1
            islocation = true
            speak2(CurrentLocation)
            print(CurrentLocation)
            islocation = false
        }
    }
    
    /// 내 Firebase DB 주소 저장
    var ref : DatabaseReference! = Database.database().reference()
    
    func savingLocation() {
        let currentTime = Date().timeIntervalSince1970
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let currentDateString = formatter.string(from: Date())
        
        if saveLocation && (lastSavedTime == 0 || (currentTime - lastSavedTime) > savingLocationInterval) {

            locationModeOn()

            var coordinate = CLLocation()
            var location = ""

            /// 5초 간격으로 현재 위치의 coordinate 받아온 뒤, 지리 좌표로 변환하여 location에 저장
            coordinate = getCurrentCoordinate() //좌표
            location = getCurrentGeolocation(currentCLLocation: coordinate) //좌표 변환 location
            
            /// Firebase DB location에 정보 저장
            let userRef = self.ref.child("location\(Firecount)")
            userRef.setValue(["location" : String(location),
                              "x" : coordinate.coordinate.latitude, //String(locValue.latitude),
                              "y": coordinate.coordinate.longitude,
                              "time": currentDateString])
            Firecount+=1
            
            //debugging
            print(CurrentLocation)
            print("================")
            
            lastSavedTime = Date().timeIntervalSince1970
        }
    }
}

extension ViewController {
    func configureCaptureSession() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            //.builtInDualWideCamera /builtInWideAngleCamera
            fatalError("No depth video camera available")
        }

        depthSession.sessionPreset = .photo
        
        do{
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            depthSession.addInput(cameraInput)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        depthSession.addOutput(videoOutput)
        
        let videoConnection = videoOutput.connection(with: .video)
        videoConnection?.videoOrientation = .landscapeRight
        
        let depthOutput = AVCaptureDepthDataOutput()
        depthOutput.setDelegate(self, callbackQueue: dataOutputQueue)
        depthOutput.isFilteringEnabled = true
        depthSession.addOutput(depthOutput)
        
        let outputRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let videoRect = videoOutput
          .outputRectConverted(fromMetadataOutputRect: outputRect)
        let depthRect = depthOutput
          .outputRectConverted(fromMetadataOutputRect: outputRect)

        scale =
          max(videoRect.width, videoRect.height) /
          max(depthRect.width, depthRect.height)

        do {
          try camera.lockForConfiguration()

          if let format = camera.activeDepthDataFormat,
            let range = format.videoSupportedFrameRateRanges.first  {
            camera.activeVideoMinFrameDuration = range.minFrameDuration
          }

          camera.unlockForConfiguration()
        } catch {
          fatalError(error.localizedDescription)
        }
    }
}

// MARK: -Capture Depth Data Delegate Methods
extension ViewController: AVCaptureDepthDataOutputDelegate{
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        
        var convertedDepth: AVDepthData
        
        let depthDataType = kCVPixelFormatType_DisparityFloat32
        if depthData.depthDataType != depthDataType{
            convertedDepth = depthData.converting(toDepthDataType: depthDataType)
        } else {
            convertedDepth = depthData
        }
        
        let pixelBuffer = convertedDepth.depthDataMap
        pixelBuffer.clamp()
        
        let depthMap = CIImage(cvPixelBuffer: pixelBuffer)
        
        DispatchQueue.main.async { [weak self] in
          self?.depthMap = depthMap
        }
        
    }
}
