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

    // MARK: -Convert CIImage to CGImage
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context = CIContext(options: nil)
        return context.createCGImage(inputImage, from: inputImage.extent)

    }

    // MARK: -Convert UIImage to CGImage
    func convertUIImageToCGImage(inputImage: UIImage) ->CGImage! {
        let convertedImage = CIImage(image: inputImage)
        return convertCIImageToCGImage(inputImage: convertedImage!)
    }

    // MARK: -Obtain Pixel Values from CGImage
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

    // MARK: -Normalizing Depth data
    func normalizeByteData(byte: UInt8) -> Double {
        
        let pixelDepth = 255.0
        let numberofPlaces = 3.0
        let multiplier = pow(10.0, numberofPlaces)
        
        return round(Double(byte) / pixelDepth * multiplier) / multiplier
    }
}
