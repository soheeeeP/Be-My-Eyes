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
    
    /* Label map
     0: rider        orange
     1: building     gray
     2: car          blue
     3: polegroup    white gray
     4: fence        beige
     5: person       red
     6: road         purple
     7: sidewalk     pink
     8: trafficsign  yellow
     9: sky          sky
     10: vegetation  green
     11: unlabeled   black
    */
    
    // convert the MLMultiArray to a MultiArray
    let codes = MultiArray<Float32>(_probs)
    // get the shape information from the probs
    let height = codes.shape[1]
    let width = codes.shape[2]
    var text = ""
    
    //00 is Left Up
    let ww = Int(width/16)
    var cell = Array(repeating: 0, count: 16)  //w=ww*i 일 때, road가 아닌 장애물이 발견되는 height 저장
    //var min = 352  //장애물이 가장 멀리 있는 cell 장애물 높이 저장
    var min_key = 0  //장애물이 가장 멀리 있는 cell index 저장
    
    var heightDistance = 0
    var widthDistance = 0
    var cellDistance = 0  //distance between each cell's obstacle and the user
    var minDistance = Int(sqrt((pow(352,2) + pow(Double(width/2), 2)))) //default distance

    let limit = Int(height/4*3)

    for i in 0...15 {
        //initializing distance for each cell
        for h in 0 ..< height {
            if Int(codes[0, height-1-h, ww*i]) != 6 {
                cell[i] = height-1-h  //w=ww*i 일 때, road가 아닌 장애물이 발견되는 height 저장

                //print("cell[\(i)]: \(cell[i]), codes: \(Int(codes[0, cell[i], ww*i]))")

                break
            }
        }
            // find a distance between each cell's obstacle and the user
            // user location :       (0,width/2)
            // obstacle location:    (cell[i],ww*i)
            
        heightDistance = cell[i]
        widthDistance = ((ww*i)-(width/2))
        cellDistance = Int(sqrt((pow(Double(heightDistance), 2) + pow(Double(widthDistance),2))))

    //        if min > cell[i]{
    //            min = cell[i]
    //            min_key = i
    //        }
            
        if(minDistance > cellDistance){
            minDistance = cellDistance
            min_key = i
        }

    }
       var cnt = 0
       //장애물이 limit영역밖에 위치하는 경우
       for i in 0...15 {
           //print("\(cell[i]), \(limit)")
           if(cell[i] < limit){
               break
           }
           cnt += 1
           /*
           if(cell[i] > limit){
               text = "Go straight"
               print("safe area")
               return text
           }
    */
       }
       if(cnt == 16){
           text = "Go straight"
           print("safe area")
           return text
       }

    print("cell index:\(min_key), distance:\(minDistance)")


    if minDistance > Int(pow(Double(height-35),2)) {
        text = "It's blocked. Go back"
    } else if min_key < 5 {
        text = "move left"
    } else if min_key > 10 {
        text = "move right"
    } else{
        text = "Go straight"
    }
    
    // return text to print and make TTS
    return text

}
