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

    
    // print(label_map[Int(codes[0, 20, 20])]) //출력 형식 : Optional([128, 64, 128])
    // print(Int(codes[0, 20, 20])) //출력 형식 : key값 int 숫자
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

/// Obstacle information of previous frame
struct PrevFrame{
    static var obstacle = Array(repeating: 6, count: 16)  //initialize to road (no obstacle)
    static var height = Array(repeating: 0, count: 16)
    static var totalCnt = Array(repeating: 0, count: 16)
}

/// Obstacle information of current frame
struct CurFrame{
    static var obstacle = Array(repeating: 6, count: 16)  //initialize to road (no obstacle)
    static var height = Array(repeating: 0, count: 16)
}

/// Locate the obstacle & Return in text
func FindObject(_ _probs: MLMultiArray) -> String {
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
    
    // 00 is Left Up
    let ww = Int(width/16)
    var cell = Array(repeating: 0, count: 16)  //w=ww*i 일 때, road가 아닌 장애물이 발견되는 height 저장
    
    var heightDistance = 0
    var widthDistance = 0
    var cellDistance = 0  //distance between each cell's obstacle and the user
    var minDistance = Int(sqrt((pow(352,2) + pow(Double(width/2), 2))))  // default distance
    var min_key = 0  // 장애물이 가장 멀리 있는 cell index 저장
    
    var obstacleFlag = false
    var obstacleText = "And Be Careful. "

    // calculate obstacle distance for each cell
    for i in 0...15 {
        for h in 0 ..< height {
            if Int(codes[0, height-1-h, ww*i]) != 6 {
                cell[i] = height-1-h  //w=ww*i 일 때, road가 아닌 장애물이 발견되는 height 저장
                CurFrame.obstacle[i] = Int(codes[0,height-1-h,ww*i])
                CurFrame.height[i] = height-1-h
                // print("cell[\(i)]: \(cell[i]), codes: \(Int(codes[0, cell[i], ww*i]))")
                break
            }
        }
    }
    
    // find a distance between each cell's obstacle and user
    // user location :       (0,width/2)
    // obstacle location:    (cell[i],ww*i)
    for i in 0...15 {
        heightDistance = cell[i]
        widthDistance = ((ww*i)-(width/2))
        cellDistance = Int(sqrt((pow(Double(heightDistance), 2) + pow(Double(widthDistance),2))))
        
        if minDistance > cellDistance {
            if (i>0 && cell[i-1] <= height*3/4) || (i<15 && cell[i+1] <= height*3/4) {
                minDistance = cellDistance
                min_key = i
            }
        }
        
        if CurFrame.obstacle[i] == PrevFrame.obstacle[i] {
            if CurFrame.height[i] > PrevFrame.height[i] {  // 장애물이 다가오는 경우
                PrevFrame.totalCnt[i]+=1
            } else if CurFrame.height[i] < PrevFrame.height[i] { // 장애물이 멀어지는 경우
                PrevFrame.totalCnt[i]-=1
            }
        }
        
        // info of prev frame obstacle
        PrevFrame.obstacle[i] = CurFrame.obstacle[i]
        PrevFrame.height[i] = CurFrame.height[i]

        // 동일한 장애물이 5 frame 연속으로 다가오는 경우 경보
        if PrevFrame.totalCnt[i] > 4 {
            //print("You are in danger. \(PrevFrame.obstacle[i]) is coming")
            obstacleText += "\(FindObstacle(code: PrevFrame.obstacle[i])) "
            obstacleFlag = true
        }
    }
//
//    if obstacleFlag {
//        PrevFrame.totalCnt = Array(repeating: 0, count: 16)  // initialize totalCnt
//    }

//    print("cell index:\(min_key), distance:\(minDistance)")

    
    // straight 영역의 장애물이 limit보다 멀리 있는 경우 straight부터 가도록 알림
    for i in 5...10 {
        if cell[i] > height/4 {  // limit == height/4
            break
        }
        if i == 10 {
            text = "Go straight"
            print("Safe Area")
            return text
        }
    }

    if minDistance > Int(sqrt(pow(Double(height-35),2))) {
        text = "It's blocked. Go back. "
    } else if min_key < 5 {
        text = "move left. "
    } else if min_key > 10 {
        text = "move right. "
    } else{
        text = "Go straight. "
    }
    
    if obstacleFlag {
        PrevFrame.totalCnt = Array(repeating: 0, count: 16)  // initialize totalCnt
        text = text + obstacleText + "is in front of you."
        
    }
    print(text)
    // return text to print and make TTS
    return text
}

func FindObstacle(code: Int) -> String{
    
    var obstacle = ""
    
    switch code {
        case 0:
            obstacle = "rider"
        case 1:
            obstacle = "building"
        case 2:
            obstacle = "car"
        case 3:
            obstacle = "polegroup"
        case 4:
            obstacle = "fence"
        case 5:
            obstacle = "person"
        case 7:
            obstacle = "sidewalk"
        case 8:
            obstacle = "trafficsign"
        case 9:
            obstacle = "sky"
        case 10:
            obstacle = "vegetation"
        case 11:
            obstacle = "unlabeled obstacle"
        default:
            obstacle = ""
    }
    
    return obstacle
}
