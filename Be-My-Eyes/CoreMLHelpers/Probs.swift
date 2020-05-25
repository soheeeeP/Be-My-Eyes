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
    /*
    if key == 5 {
        text = "There is a person. Move to right"
    } else if key == 1 {
        text = "There is a car. Move to left"
    }*/
    
    //00 is Left Up
    let ww = Int(width/16)
    var cell : Array<Int> = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]  //w=ww*i 일 때, road가 아닌 장애물이 발견되는 height 저장
    //var tan : Array<Int> = [0,0,0,0,0,0,0,0]  //각 cell의 장애물 위치 기울기(Tangent value) 저장
    //let mid = width/2
    var min = 350  //cell 중 가장 높은 위치를 갖는 index 저장
    var min_key = 0;
    
    for i in 0...15 {
        for h in 0 ..< height {
            if Int(codes[0, height-1-h, ww*i]) != 6 {
                cell[i] = height-1-h  //w=ww*i 일 때, road가 아닌 장애물이 발견되는 height 저장
                //print("cell[\(i)] = \(cell[i]), codes=\(Int(codes[0, height-1-h, ww*i]))")
                break
            }
        }
        if min > cell[i] {
            min = cell[i]
            min_key = i
        }
    }
   // print("\(min_key), \(min)")
    

    if min > height - 35{
        text = "It's blocked. Go back"
    }
    else{
        if min_key < 5{
            text = "move left"
        }
        else if min_key > 10{
            text = "move right"
        }
        else{
            text = "Go straight"
        }
    }
    
    // return text to make TTS
    return text
}
