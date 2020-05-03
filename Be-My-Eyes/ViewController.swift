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

/// A view controller to pass camera inputs through a vision model
class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// a local reference to time to update the framerate
    var time = Date()
    
    var ready: Bool = true

    /// the view to preview raw RGB data from the camera
    @IBOutlet weak var preview: UIView!
    /// the view for showing the segmentation
    @IBOutlet weak var segmentation: UIImageView!
    /// a label to show the framerate of the model
    @IBOutlet weak var framerate: UILabel!
    
    /// the camera session for streaming data from the camera
    var captureSession: AVCaptureSession!
    /// the video preview layer
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
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

    /// the model for the view controller to apss camera data through
    private var _model: VNCoreMLModel?
    /// the model for the view controller to apss camera data through
    var model: VNCoreMLModel! {
        get {
            // try to unwrap the private model instance
            if let model = _model {
                return model
            }
            // try to create a new model and fail gracefully
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
            }
            // set the input image size to be a scaled version
            // of the image
            _request?.imageCropAndScaleOption = .scaleFill
            return _request
        }
    }
}
