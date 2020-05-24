//
//  AppDelegate.swift
//  Be-My-Eyes
//
//  Created by Be-My-Eyes on 04/28/20.
//  Copyright © 2020 Be-My-Eyes. All rights reserved.
//

import Foundation
import UIKit
import CoreML

/// Convert probability tensor into an image
func codesToImage(_ _probs: MLMultiArray) -> UIImage? {
    // TODO: dynamically load a label map instead of hard coding
    // can this bonus data be included in the model file?
    let label_map = [
        0:  [255, 0, 0],        //0 : rider
        1:  [70, 70, 70],       //1 : building
        2:  [0, 0, 142],        //2 : car
        3:  [153, 153, 153],    //3 : pole
        4:  [190, 153, 153],    //4 : fence
        5:  [220, 20, 60],      //5 : person
        6:  [128, 64, 128],     //6 : road
        7:  [244, 35, 232],     //7 : sidewalk
        8:  [220, 220, 0],      //8 : traffic sign
        9:  [70, 130, 180],     //9 : sky
        10: [107, 142, 35],     //10 : vegetation
        11: [0, 0, 0]           //11 :
    ]
    //5 : 빨강
    //6 : 도로
    //7 : 인도
    
    // convert the MLMultiArray to a MultiArray
    let codes = MultiArray<Float32>(_probs)
    // get the shape information from the probs
    let height = codes.shape[1]
    let width = codes.shape[2]
    // initialize some bytes to store the image in
    var bytes = [UInt8](repeating: 255, count: height * width * 4)
    // iterate over the pixels in the output probs

    
    //print(label_map[Int(codes[0, 20, 20])]) //출력 형식 : Optional([128, 64, 128])
    //print(Int(codes[0, 20, 20])) //출력 형식 : key값 int 숫자
    for h in 0 ..< height {
        for w in 0 ..< width {
            // get the array offset for this word
            let offset = h * width * 4 + w * 4
            // get the RGB value for the highest probability class
            let rgb = label_map[Int(codes[0, h, w])]
            // set the bytes to the RGB value and alpha of 1.0 (255)
            bytes[offset + 0] = UInt8(rgb![0])
            bytes[offset + 1] = UInt8(rgb![1])
            bytes[offset + 2] = UInt8(rgb![2])
        }
    }
    // create a UIImage from the byte array
    return UIImage.fromByteArray(bytes, width: width, height: height,
                                 scale: 0, orientation: .up,
                                 bytesPerRow: width * 4,
                                 colorSpace: CGColorSpaceCreateDeviceRGB(),
                                 alphaInfo: .premultipliedLast)
}


func FindObject(_ _probs: MLMultiArray) -> String {
    // TODO: dynamically load a label map instead of hard coding
    // can this bonus data be included in the model file?
    let label_map = [
        0:  [255, 0, 0],        //0 : rider 완전빨강색
        1:  [70, 70, 70],       //1 : building 진한 회색
        2:  [0, 0, 142],        //2 : car 샛파랑색
        3:  [153, 153, 153],    //3 : pole 연한 회색
        4:  [190, 153, 153],    //4 : fence 칙칙한 핑크색
        5:  [220, 20, 60],      //5 : person 빨강색
        6:  [128, 64, 128],     //6 : road 연보라색
        7:  [244, 35, 232],     //7 : sidewalk 핑크색
        8:  [220, 220, 0],      //8 : traffic sign 노랑색
        9:  [70, 130, 180],     //9 : sky 탁탁한 파랑색
        10: [107, 142, 35],     //10 : vegetation 탁탁한 연두색
        11: [0, 0, 0]           //11 :
    ]
  
    
    // convert the MLMultiArray to a MultiArray
    let codes = MultiArray<Float32>(_probs)
    // get the shape information from the probs
    let height = codes.shape[1]
    let width = codes.shape[2]
    
    var text = ""
    let temp:Int = ((height/2) * (width/3))/3
    
    var left = 1
    for h in height/2..<height {
        for w in 0..<width/3{
            if Int(codes[0, h, w]) == 6 || Int(codes[0, h, w]) == 7{
                left += 1
            }
        }
    }
    
    var center = 1
    for h in height/2..<height {
        for w in width/3..<width/3*2{
            if Int(codes[0, h, w]) == 6 || Int(codes[0, h, w]) == 7{
                center += 1
            }
        }
    }
    
    var right = 1
    for h in height/2..<height {
        for w in width/3*2..<width{
            if Int(codes[0, h, w]) == 6 || Int(codes[0, h, w]) == 7{
                right += 1
            }
        }
    }
    print("\(temp), \(left), \(center), \(right)")
    if left > temp{
        left = 0
    }
    if center > temp{
        center = 0
    }
    if right > temp{
        right = 0
    }
    if left * center * right != 0{
        text = "There is no way to go"
    }
    else if left == 0 && center * right != 0{
        text = "move left"
    }
    else if right == 0 && center * left != 0{
        text = "move right"
    }
    else if center != 0 && left == 0 && right == 0{
        text = "move left or right"
    }
    else{
        text = "go straight"
    }
    
    /*
    // initialize some bytes to store the image in
    var bytes = [UInt8](repeating: 255, count: height * width * 4)
    // iterate over the pixels in the output probs
    for h in 0 ..< height {
        for w in 0 ..< width {
            // get the array offset for this word
            let offset = h * width * 4 + w * 4
            // get the RGB value for the highest probability class
            let rgb = label_map[Int(codes[0, h, w])]
            // set the bytes to the RGB value and alpha of 1.0 (255)
            bytes[offset + 0] = UInt8(rgb![0])
            bytes[offset + 1] = UInt8(rgb![1])
            bytes[offset + 2] = UInt8(rgb![2])
        }
    }
 */
    
    // return text to make TTS
    return text
}
