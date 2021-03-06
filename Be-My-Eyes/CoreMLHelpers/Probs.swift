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

let depthView = depthViewController()

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

/// Convert probability tensor into an image
func codesToImage(_ _probs: MLMultiArray) -> UIImage? {
    // TODO: dynamically load a label map instead of hard coding
    // convert the MLMultiArray to a MultiArray
    let codes = MultiArray<Float32>(_probs)
    // get the shape information from the probs
    let height = codes.shape[1]
    let width = codes.shape[2]
    // initialize some bytes to store the image in
    var bytes = [UInt8](repeating: 255, count: height * width * 4)
    
    // print(label_map[Int(codes[0, 20, 20])]) //출력 형식 : Optional([128, 64, 128])
    // print(Int(codes[0, 20, 20])) //출력 형식 : key값 int 숫자
    
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
    // create a UIImage from the byte array
    return UIImage.fromByteArray(bytes, width: width, height: height,
                                 scale: 0, orientation: .up,
                                 bytesPerRow: width * 4,
                                 colorSpace: CGColorSpaceCreateDeviceRGB(),
                                 alphaInfo: .premultipliedLast)
}
/// Gererate Black-and-White image as a visual aid
func codesToBlackAndWhiteImage(_ _probs: MLMultiArray) -> UIImage? {
    // convert the MLMultiArray to a MultiArray
    let codes = MultiArray<Float32>(_probs)
    // get the shape information from the probs
    let height = codes.shape[1]
    let width = codes.shape[2]
    // initialize some bytes to store the image in
    var bytes = [UInt8](repeating: 255, count: height * width * 4)
    
    // iterate over the pixels in the output probs
    for h in 0 ..< height {
        for w in 0 ..< width {
            // get the array offset for this word
            let offset = h * width * 4 + w * 4
            // get the RGB value for the highest probability class
            let object = Int(codes[0, h ,w])
    
            if object != 6 && object != 7 { //인도, 또는 도로가 아닌 경우 검은색
                bytes[offset + 0] = UInt8(0)
                bytes[offset + 1] = UInt8(0)
                bytes[offset + 2] = UInt8(0)
            } else {
                //인도, 또는 도로인 경우 흰색
                bytes[offset + 0] = UInt8(255)
                bytes[offset + 1] = UInt8(255)
                bytes[offset + 2] = UInt8(255)
            }

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
    static var obstacle = Array(repeating: 6, count: 20)  //initialize to road (no obstacle)
    static var height = Array(repeating: 0, count: 20)
    static var totalCnt = Array(repeating: 0, count: 20)
    static var depthHeight = Array(repeating: 0.0, count: 20)
}

/// Obstacle information of current frame
struct CurFrame{
    static var obstacle = Array(repeating: 6, count: 20)  //initialize to road (no obstacle)
    static var height = Array(repeating: 0, count: 20)
    static var depthHeight = Array(repeating: 0.0, count: 20)
}

var obstacle = ""
var obstacleFlag = false
var obstacleDistance = 0
var obstacle_idx = 6;
var didAppeared = Array(repeating: 0, count: 20)
var idxAppeared = Array(repeating: 0, count: 12)
var safeArea = false

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
    let ww = Int(width/20)
    var cell = Array(repeating: 0, count: 20)  //w=ww*i 일 때, road가 아닌 장애물이 발견되는 height 저장
    
    var cellDistance = 0  // distance between each cell's obstacle and the user
    var minDistance = Int(sqrt((pow(352,2) + pow(Double(width/2), 2))))  // most far distance
    var minKey = 0  // most far cell index
    
    let wwPixel = Int(180/20)
    var hhPixel = 0
    var nValue = 0.0
    var depthDetected = Array(repeating: false, count: 20)  //한 cell에서 한 번씩만 확인하도록 flag 설정
    
    // calculate obstacle distance for each cell
    for i in 0...19 {
        for h in stride(from: 50, to: height, by: 2) { // for speed   // for h in 50 ..< height {
            if Int(codes[0, height-1-h, ww*i]) != 6 && Int(codes[0, height-1-h, ww*i]) != 7 {  // 인도 또는 도로가 아닌 경우
                cell[i] = height-1-h  //w=ww*i 일 때, road가 아닌 장애물이 발견되는 height 저장 (위를 0으로 계산)
                CurFrame.obstacle[i] = Int(codes[0,height-1-h,ww*i])
                CurFrame.height[i] = height-1-h
                break
            }
            else {
                if depthDetected[i] == false {
                    //label에서는 인도나 도로라고 인식되지만, depth값의 장애물 임계치를 넘는 pixel값을 가지는 경우
                    hhPixel = Int(Double(height-1-h) * 0.9)
                    nValue = depthView.normalizeByteData(byte: pixelData[hhPixel][wwPixel*i])
                    if nValue > 0.75 {
                        print("cell[\(i)] : depth detected at pixelData[\(hhPixel)][\(wwPixel*i)]")
                        //normalize된 값이 0.75이상(pixel값 192이상)이면, 해당 cell을 obstacle이 존재하는 cell이라고 인지하도록 설정
                        cell[i] = height-51 //blocked cell처리
                        CurFrame.height[i] = height-51
                        CurFrame.depthHeight[i] = Double(cell[i]) * sqrt(nValue*nValue + 1)
                        depthDetected[i] = true
                    }
                }
            }
        }
    }
    
    // find a distance between each cell's obstacle and user
    // user location :       (0, width/2)
    // obstacle location:    (cell[i], ww*i)
    for i in 0...19 {
        // cellDistance = Int(sqrt((pow(Double(cell[i]), 2) + pow(Double((ww*i)-(width/2)),2))))
        cellDistance = cell[i]
        
        if depthDetected[i] == true {
            continue
        }
        if minDistance > cellDistance {
            if (i>0 && cell[i-1] <= height*3/4) || (i<15 && cell[i+1] <= height*3/4) {
                minDistance = cellDistance
                minKey = i
            }
        }
        
        if i>6 && i<13 { // straight 영역 : 7...12
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

            // 동일한 장애물이 4 frame 연속으로 다가오는 경우 경보
            if (PrevFrame.totalCnt[i] > 3) {
                if didAppeared[PrevFrame.totalCnt[i]] == 0 {
                    didAppeared[PrevFrame.totalCnt[i]] = 1
                    // obstacleDistance = (10 - PrevFrame.height[i] / 35) * 2
                    if userStride == "" {
                        userStride = "35"
                    }
                    obstacleDistance = DistObstacle(height: PrevFrame.height[i], stride: Int(userStride)!)
                    obstacle = FindObstacle(code: PrevFrame.obstacle[i])
                    obstacle_idx = PrevFrame.obstacle[i]
                    
                    // 장애물이 존재하는 경우 메세지 추가 & 장애물 flag 설정
                    if obstacle != "" {
                        obstacleFlag = true
                    }
                }
            }
        }
    }
    //print("cell index:\(min_key), distance:\(minDistance)")
    
    // straight 영역의 장애물이 limit보다 멀리 있는 경우 straight부터 가도록 알림
    safeArea = false
    for i in 7...12 {
        if cell[i] > height/4 {  // limit == height/4
            break
        }
        if i == 12 {
            text = "Go straight."
            print("Safe Area")
            minKey = 10
            safeArea = true
        }
    }
    
    if safeArea == false {
        // Navigation message
        if minDistance > Int(height-40) {
            text = "It's blocked. Go back."
        } else if minKey < 7 {
            text = "Move left."
        } else if minKey > 12 {
            text = "Move right."
        } else {
            text = "Go straight."
        }
        
        // Obstacle detecting message
        if obstacleFlag {
            PrevFrame.totalCnt = Array(repeating: 0, count: 16)  // initialize totalCnt
            didAppeared = Array(repeating: 0, count: 16)  // initialize didAppeared
        }
    }
    // debugging TTS message
    print(text + " cell : \(minKey)")
    print("user stride : " + userStride)

    // return text to print and make TTS
    return text
}

func FindObstacle(code: Int) -> String {
    var obstacle = ""
    switch code {
        case 0:
            obstacle = "Rider"
        case 1:
            obstacle = "Building"
        case 2:
            obstacle = "Car"
        case 3:
            obstacle = "Polegroup"
        case 4:
            obstacle = "Fence"
        case 5:
            obstacle = "Person"
        case 8:
            obstacle = "Traffic sign"
        case 10:
            obstacle = "Vegetation"
        default:
            obstacle = ""
    }
    return obstacle
}

/// Calibration
func DistObstacle(height: Int, stride: Int) -> Int { // (10 - PrevFrame.height[i] / 35) * 2
    var foot = 0
    //stride = 35 시각장애인 평균 보폭
    switch height {
        case 290 ..< 302:
            foot = 0
        case 275 ..< 290:
            foot = 90/stride //45*2
        case 250 ..< 275:
            foot = 135/stride //45*3
        case 230 ..< 250:
            foot = 180/stride //45*4
        case 210 ..< 230:
            foot = 225/stride //45*5
        case 195 ..< 210:
            foot = 270/stride //45*6
        case 180 ..< 195:
            foot = 315/stride //45*7
        case 170 ..< 180:
            foot = 360/stride //45*8
        case 160 ..< 170:
            foot = 405/stride //45*9
        case 150 ..< 160:
            foot = 450/stride //45*10
        default:
            foot = 495/stride //45*11
    }
    return foot
}

func obtainPixelData() {
    //pixel height = 320
    for h in stride(from: 50, to: 320, by: 2) {
        for j in stride(from: 0, to: 180, by: 12) {
            //normalized pixel data
            print(depthView.normalizeByteData(byte: pixelData[h][j]), terminator: " ")
//            print(round(Double(pixelData[h][j]) / pixelDepth * multiplier) / multiplier, terminator:" ")
        }
        print("\n")
    }
    print("------------------------------------")
}
