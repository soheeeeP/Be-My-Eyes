//
//  depthViewController.swift
//  Be-My-Eyes
//
//  Created by 박소희 on 2020/07/16.
//  Copyright © 2020 Kautenja. All rights reserved.
//

import UIKit
import AVFoundation

class depthViewController: UIViewController {

    @IBOutlet weak var previewView: UIImageView!
    
    let session = AVCaptureSession()
    let dataOutputQueue = DispatchQueue(label: "video data queue",
                                        qos: .userInitiated,
                                        attributes: [],
                                        autoreleaseFrequency: .workItem)

    var depthMap: CIImage?
    var scale: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCaptureSession()
        session.startRunning()
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

// MARK: -Helper Methods
extension depthViewController {
    func configureCaptureSession() {
    
        guard let camera = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .unspecified) else {
          fatalError("No depth video camera available")
        }

        session.sessionPreset = .photo
        
        do{
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            session.addInput(cameraInput)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        session.addOutput(videoOutput)
        
        let videoConnection = videoOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
        
        let depthOutput = AVCaptureDepthDataOutput()
        depthOutput.setDelegate(self, callbackQueue: dataOutputQueue)
        depthOutput.isFilteringEnabled = true
        session.addOutput(depthOutput)
        
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

// MARK: -Capture Video Data Delegate Methods
extension depthViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let image = CIImage(cvPixelBuffer: pixelBuffer!)

        let previewImage: CIImage
        
        previewImage = depthMap ?? image
        
        let displayImage = UIImage(ciImage: previewImage)
        DispatchQueue.main.async { [weak self] in
            self?.previewView.image = displayImage
        }
    }
}

// MARK: -Capture Depth Data Delegate Methods
extension depthViewController: AVCaptureDepthDataOutputDelegate{
    func depthDataOutput(_ output: AVCaptureDepthDataOutput,
                         didOutput depthData: AVDepthData,
                         timestamp: CMTime,
                         connection: AVCaptureConnection) {
        
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
