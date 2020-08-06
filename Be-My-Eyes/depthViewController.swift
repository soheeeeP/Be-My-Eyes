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
    
    let depthSession = AVCaptureSession()
    let dataOutputQueue = DispatchQueue(label: "video data queue",
                                        qos: .userInitiated,
                                        attributes: [],
                                        autoreleaseFrequency: .workItem)

    var depthMap: CIImage?
    var scale: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCaptureSession()
        depthSession.startRunning()
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
    
        /// iPhone11 : builtInDualWideCamera   iPhoneX : builtInDualCamera   iPhone8 : builtInWideAngleCamera
        guard let camera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else {
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
        
        let displayImage = UIImage(ciImage: depthMap)
        
        DispatchQueue.main.async { [weak self] in
          self?.depthMap = depthMap
            
            self!.pixelValues(fromCGImage: self!.convertCIImageToCGImage(inputImage: depthMap), width: Int(displayImage.size.width), height: Int(displayImage.size.height))
        }
    }
}
// MARK: -Convert CIImage to CGImage
extension depthViewController {
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context = CIContext(options: nil)
        return context.createCGImage(inputImage, from: inputImage.extent)

    }
}

// MARK: -Convert UIImage to CGImage
extension depthViewController {
    func convertUIImageToCGImage(inputImage: UIImage) ->CGImage! {
        let convertedImage = CIImage(image: inputImage)
        return convertCIImageToCGImage(inputImage: convertedImage!)
    }
}

// MARK: -Obtain Pixel Values from CGImage
extension depthViewController {
    func pixelValues(fromCGImage imageRef: CGImage?, width: Int, height: Int) -> [[UInt8]]?
    {

        var pixelValues: [UInt8]?
        var minimizedPixelValues = [[UInt8]](repeating: [UInt8](repeating: 0, count: width), count: height)
        if let imageRef = imageRef {

            let bitsPerComponent = imageRef.bitsPerComponent
            let bytesPerRow = imageRef.bytesPerRow
            let totalBytes = height * bytesPerRow

            let colorSpace = CGColorSpaceCreateDeviceGray()
            var intensities = [UInt8](repeating: 0, count: totalBytes)

            let contextRef = CGContext(data: &intensities, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: 0)
            contextRef?.draw(imageRef, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))

            pixelValues = intensities
            
            for i in stride(from: 0, to: 320, by: 1){
                for j in stride(from: 0, to: width, by: 1){
                    minimizedPixelValues[i][j]=pixelValues![i*bytesPerRow + j]
                }
            }
        }
        return minimizedPixelValues
    }

}
