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
    var isPrepared = false
    var str: String = "Depth to Grayscale Converter"
    
    var inputFormatDescription: CMFormatDescription?
    var outputFormatDescription: CMFormatDescription?
    
    var inputTextureFormat: MTLPixelFormat = .invalid
    var outputPixelBufferPool: CVPixelBufferPool!
    var textureCache: CVMetalTextureCache!
    
    let metalDevice = MTLCreateSystemDefaultDevice()!
    
    private var lowest: Float = 0.0
    private var highest: Float = 0.0
    struct DepthRenderParam {
        var offset: Float
        var range: Float
    }
    var range: DepthRenderParam = DepthRenderParam(offset: -4.0, range: 8.0)
    
    private var computePipelineState: MTLComputePipelineState?
    private lazy var commandQueue: MTLCommandQueue? = {
        return self.metalDevice.makeCommandQueue()
    }()
    
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
    
        guard let camera = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else {
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

        var videoRectMax = 0.0
        if(videoRect.width>videoRect.height){
            videoRectMax = Double(videoRect.width)
        } else{
            videoRectMax = Double(videoRect.height)
        }
        
        var depthRectMax = 0.0
        if(depthRect.width>depthRect.height){
            depthRectMax = Double(depthRect.width)
        } else {
            depthRectMax = Double(depthRect.height)
        }
        scale = CGFloat(videoRectMax / depthRectMax)
        
//        scale =
//          max(videoRect.width, videoRect.height) /
//          max(depthRect.width, depthRect.height)

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
        //pixelbuffer를 변환하는 함수
        //c(lamp()대신 render() 사용?
        pixelBuffer.clamp()
        
        ///
        if !self.isPrepared {
            var depthFormatDescription: CMFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &depthFormatDescription)
            
            if let unwrappedDepthFormatDescription = depthFormatDescription {
                //prepare
                prepare(with: unwrappedDepthFormatDescription, outputRetainedBufferCountHint: 3)
            }
        }
        
        guard let convertedDepthPixelBuffer = render(pixelBuffer: pixelBuffer) else{
            print("unable to convert depth pixel buffer")
            return
        }
        
        ///
        //let depthMap = CIImage(cvPixelBuffer: pixelBuffer)
        let depthMap = CIImage(cvPixelBuffer: convertedDepthPixelBuffer)
        DispatchQueue.main.async { [weak self] in
          self?.depthMap = depthMap
        }
        
    }
}

extension depthViewController {
    func allocateOutPutBuffers(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) -> CVPixelBufferPool? {
        let inputDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        let outputPixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(inputDimensions.width),
            kCVPixelBufferHeightKey as String: Int(inputDimensions.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: outputRetainedBufferCountHint]
        var cvPixelBufferPool: CVPixelBufferPool?
        // Create a pixel buffer pool with the same pixel attributes as the input format description
        CVPixelBufferPoolCreate(kCFAllocatorDefault,
                                poolAttributes as NSDictionary?,
                                outputPixelBufferAttributes as NSDictionary?,
                                &cvPixelBufferPool)
        guard let pixelBufferPool = cvPixelBufferPool else {
            assertionFailure("Allocation failure: Could not create pixel buffer pool")
            return nil
        }
        return pixelBufferPool
        
    }
    
    func makeTextureFromCVPixelBuffer(pixelBuffer: CVPixelBuffer, textureFormat: MTLPixelFormat) -> MTLTexture? {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Create a Metal texture from the image buffer
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, textureFormat, width, height, 0, &cvTextureOut)
        guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
            print("Depth converter failed to create preview texture")
            
            CVMetalTextureCacheFlush(textureCache, 0)
            
            return nil
        }
        
        return texture
    }

    
    func reset() {
        isPrepared = false
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        textureCache = nil
    }
    
    func prepare(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int){
        reset()
        
        outputPixelBufferPool = allocateOutPutBuffers(with: formatDescription, outputRetainedBufferCountHint: outputRetainedBufferCountHint)
        
        if outputPixelBufferPool == nil{
            return
        }
        
        var pixelBuffer: CVPixelBuffer?
        var pixelBufferFormatDescription: CMFormatDescription?
        _ = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool!, &pixelBuffer)
        if let pixelBuffer = pixelBuffer {
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                         imageBuffer: pixelBuffer,
                                                         formatDescriptionOut: &pixelBufferFormatDescription)
        }
        pixelBuffer = nil
        
        inputFormatDescription = formatDescription
        outputFormatDescription = pixelBufferFormatDescription
        
        let inputMediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription)
        if inputMediaSubType == kCVPixelFormatType_DepthFloat16 ||
            inputMediaSubType == kCVPixelFormatType_DisparityFloat16 {
            inputTextureFormat = .r16Float
        } else if inputMediaSubType == kCVPixelFormatType_DepthFloat32 ||
            inputMediaSubType == kCVPixelFormatType_DisparityFloat32 {
            inputTextureFormat = .r32Float
        } else {
            assertionFailure("Input format not supported")
        }
        
        var metalTextureCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &metalTextureCache) != kCVReturnSuccess {
            assertionFailure("Unable to allocate depth converter texture cache")
        } else {
            textureCache = metalTextureCache
        }
        
        isPrepared = true
    }
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        if !isPrepared{
            assertionFailure("Invalid state: Not prepared")
            return nil
        }
        
        var newPixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool!, &newPixelBuffer)
        guard let outputPixelBuffer = newPixelBuffer else {
            print("Allocation failure: Could not get pixel buffer from pool (\(self.str))")
            return nil
        }
        guard let outputTexture = makeTextureFromCVPixelBuffer(pixelBuffer: outputPixelBuffer, textureFormat: .bgra8Unorm),
            let inputTexture = makeTextureFromCVPixelBuffer(pixelBuffer: pixelBuffer, textureFormat: inputTextureFormat) else {
                return nil
        }
        
        var min: Float = 0.0
        var max: Float = 0.0
        
        minMaxFromPixelBuffer(pixelBuffer, &min, &max, inputTextureFormat)
        if min < lowest {
            lowest = min
        }
        if max > highest {
            highest = max
        }
        range = DepthRenderParam(offset: lowest, range: highest - lowest)
        
        // Set up command queue, buffer, and encoder
        guard let commandQueue = commandQueue,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
                print("Failed to create Metal command queue")
                CVMetalTextureCacheFlush(textureCache!, 0)
                return nil
        }
        
        commandEncoder.label = "Depth to Grayscale"
        commandEncoder.setComputePipelineState(computePipelineState!)
        commandEncoder.setTexture(inputTexture, index: 0)
        commandEncoder.setTexture(outputTexture, index: 1)
        commandEncoder.setBytes( UnsafeMutableRawPointer(&range), length: MemoryLayout<DepthRenderParam>.size, index: 0)
        
        // Set up the thread groups.
        let width = computePipelineState!.threadExecutionWidth
        let height = computePipelineState!.maxTotalThreadsPerThreadgroup / width
        let threadsPerThreadgroup = MTLSizeMake(width, height, 1)
        let threadgroupsPerGrid = MTLSize(width: (inputTexture.width + width - 1) / width,
                                          height: (inputTexture.height + height - 1) / height,
                                          depth: 1)
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        
        return outputPixelBuffer

    }
}

