//
//  mapContainerView.swift
//  Be-My-Eyes
//
//  Created by 방윤 on 2020/07/05.
//  Copyright © 2020 Be-My-Eyes. All rights reserved.
//

import UIKit
import TMapSDK
import Contacts
import MapKit
import CoreLocation
import AVFoundation
import Firebase

class mapContainerView: UIViewController, TMapViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet var mapContainerView:UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchText: UITextField!
    
    /// Firebase DB
    var ref : DatabaseReference! = Database.database().reference()
    var pastCoordinate : CLLocationCoordinate2D! = CLLocationCoordinate2D()
    var nextCoordinate : CLLocationCoordinate2D! = CLLocationCoordinate2D()
    var childrenCount : Int!
    
    var mapView:TMapView?
    
    var leftArray:Array<LeftMenuData>?
    
    var texts:Array<TMapText> = []
    var markers:Array<TMapMarker> = []
    var polylines:Array<TMapPolyline> = []
    
    // 추가
    var endPointLocation: CLLocationCoordinate2D!
    var currentLocation: CLLocationCoordinate2D!
    var path: [CLLocationCoordinate2D]!
    var count = 0
    var GetDirectionTimer: Timer?
    var flag = false
    var flag2 = false
    var index = 0
    var angle: Double!
    var exAngle: Double!
    let rigth = ["1시방향", "2시방향", "3시방향", "4시방향", "5시방향"]
    let left = ["11시방향", "10시방향", "9시방향", "8시방향", "7시방향"]
    var clockAngle: Int!
    var landMark: String!
    
    @IBOutlet weak var output3: UITextField!
    @IBOutlet weak var around: UITextField!
    @IBOutlet weak var output1: UITextField!
    @IBOutlet weak var output2: UITextField!
    
    
    //임시
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        GetDirectionTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(Move), userInfo: nil, repeats: true)
        
        self.mapView = TMapView(frame: mapContainerView.frame)
        self.mapView?.delegate = self
        self.mapView?.setApiKey("l7xxf8cfdf8de7494065a7a4f2d71d12a412")
        
        
        mapContainerView.addSubview(self.mapView!)
        
        //setting leftmenu
        self.initTableViewData()
    }
    
    // Move
    @objc func Move(){
        if flag == true {
            self.currentLocation = self.mapView?.getCenter()
            for marker in self.markers {
                marker.map = nil
            }
            self.markers.removeAll()
            let marker1 = TMapMarker(position: currentLocation)
            marker1.map = self.mapView
            marker1.title = "출발지"
            marker1.icon = UIImage(named: "image")
            self.markers.append(marker1)
            //self.currentLocation = self.path[index]
            self.angle = self.mapView?.heading
            objFunc54()
            if index == count {
                output3.text = "도착했습니다."
                self.GetDirectionTimer!.invalidate()
                flag = false
                output1.text = ""
                output2.text = ""
            }
            else{
                output1.text = "현재위치" + "  \(currentLocation.latitude)" + "   " + "\(currentLocation.longitude)" + "  " + "\(Double(self.angle!))"
                output2.text = "가야할곳" + "  \(path[index].latitude)" + "   " + "\(path[index].longitude)" + "  " + "\(Double(self.exAngle!))"
                
                if sqrt(pow(currentLocation.latitude - self.path[index].latitude, 2) + pow(currentLocation.longitude - self.path[index].longitude, 2)) < 0.00003 {
                    index += 1
                    //주변 검색
                    
                    if index != count{
                        let d = sqrt(pow(currentLocation.latitude - self.path[index].latitude, 2) + pow(currentLocation.longitude - self.path[index].longitude, 2))
                        let x = (self.path[index].latitude - currentLocation.latitude)
                        let y = (self.path[index].longitude - currentLocation.longitude)
                        var a = asin(fabs(y/d)) * 180 / Double.pi
                        if x > 0 && y > 0{
                            
                        }
                        else if x > 0 && y < 0{
                            a = 360 - a
                        }
                        else if x < 0 && y > 0 {
                            a = 180 - a
                        }
                        else if x < 0 && y < 0{
                            a = 180 + a
                        }
                        if self.angle <= 180{
                            if 0 < a && a <= self.angle {
                                self.clockAngle = Int((self.angle - a) / 30)
                                if self.clockAngle < 1{
                                    output3.text = "직진하세요"
                                }
                                else{
                                    output3.text = "\(left[self.clockAngle])시 방향으로 좌회전하세요"
                                }
                            }
                            else if self.angle + 180 < a && a <= 360{
                                self.clockAngle = Int((self.angle - (a - 360)) / 30)
                                if self.clockAngle < 1{
                                    output3.text = "직진하세요"
                                }
                                else{
                                    output3.text = "\(left[self.clockAngle])시 방향으로 좌회전하세요"
                                }
                            }
                            else if self.angle < a && a < 180 + self.angle {
                                self.clockAngle = Int((a - self.angle) / 30)
                                if self.clockAngle < 1{
                                    output3.text = "직진하세요"
                                }
                                else{
                                    output3.text = "\(rigth[self.clockAngle])시 방향으로 우회전하세요"
                                }
                            }
                        }
                        else{
                            if self.exAngle < a && a < 360{
                                self.clockAngle = Int((a - self.angle) / 30)
                                if self.clockAngle < 1{
                                    output3.text = "직진하세요"
                                }
                                else{
                                    output3.text = "\(rigth[self.clockAngle])시 방향으로 우회전하세요"
                                }
                            }
                            else if 0 <= a && a < self.angle - 180 {
                                self.clockAngle = Int((a - (self.angle - 360)) / 30)
                                if self.clockAngle < 1{
                                    output3.text = "직진하세요"
                                }
                                else{
                                    output3.text = "\(rigth[self.clockAngle])시 방향으로 우회전하세요"
                                }
                            }
                            else if self.exAngle - 180 < a && a < self.exAngle{
                                self.clockAngle = Int((self.angle - a) / 30)
                                if self.clockAngle < 1{
                                    output3.text = "직진하세요"
                                }
                                else{
                                    output3.text = "\(left[self.clockAngle])시 방향으로 좌회전하세요"
                                }
                            }
                        }
                        self.exAngle = a
                        
                    }
                }
            }
        }
    }
    
    
    //search text

    @IBAction func search(_ sender: Any) {
        resignFirstResponder()
        self.objfunc56()
    }
    
    @IBAction func Back(_ sender: Any) {
        self.GetDirectionTimer!.invalidate()
        dismiss(animated: true, completion: nil)
    }


    func initTableViewData() {
        self.leftArray = Array()
        self.leftArray?.append(LeftMenuData(title: "초기화", onClick: initMapView))
        
        // 마커
        self.leftArray?.append(LeftMenuData(title: "마커 추가", onClick: objFunc01))
        self.leftArray?.append(LeftMenuData(title: "마커영역 이동", onClick: objFunc02))
        self.leftArray?.append(LeftMenuData(title: "마커 제거", onClick: objFunc03))
        
        // 경로추적
        self.leftArray?.append(LeftMenuData(title: "경로추적", onClick: objFunc_userLoc))
        
        self.leftArray?.append(LeftMenuData(title: "경로탐색", onClick: objFunc57))
        self.tableView.reloadData()
        
    }
    
}

//TalbeView delegate, DataSource
//left menu
struct LeftMenuData {
    var title: String!
    var onClick: ()->()
}

extension mapContainerView:UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return leftArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        cell = tableView.dequeueReusableCell(withIdentifier: "firstCell", for: indexPath)
        let data: LeftMenuData = (leftArray?[indexPath.row])!
        cell.textLabel?.text = data.title ?? ""
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data: LeftMenuData = (leftArray?[indexPath.row])!
        data.onClick()
    }
    
}

// MARK: - Map basic functions -

extension mapContainerView {
    //맵 초기화
    public func initMapView(){
        mapContainerView.subviews.forEach { $0.removeFromSuperview() }
        self.mapView = TMapView(frame: mapContainerView.frame)
        self.mapView?.delegate = self
        self.mapView?.setApiKey("l7xxf8cfdf8de7494065a7a4f2d71d12a412")
        self.mapView?.isRotationEnable = true
        self.mapView?.heading = 0
        self.mapView?.trackinMode = TrackingMode.followWithHeading
        self.flag2 = false
        self.count = 0
        self.index = 0
        self.flag = false
        mapContainerView.addSubview(self.mapView!)
    }
}

// MARK: - Map object functions -

extension mapContainerView {
    // 마커 추가
    public func objFunc01() {
        let position = self.mapView?.getCenter()
        if let position = position {
            let marker = TMapMarker(position: position)
            marker.title = "My Car"
            marker.subTitle = "내용없음"
            marker.draggable = true
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 50))
            label.text = "좌측"
            marker.leftCalloutView = label
            let label2 = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 50))
            label2.text = "우측"
            marker.rightCalloutView = label2
            
            marker.map = self.mapView
            self.markers.append(marker)
        }
    }
    
    // 마커 fit
    public func objFunc02() {
        self.mapView?.fitMapBoundsWithMarkers(self.markers)
    }
    
    // 마커 제거
    public func objFunc03() {
        for marker in self.markers {
            marker.map = nil
        }
        self.markers.removeAll()
    }
}

// MARK: - Map api functions -

extension mapContainerView {
    // api
    
    public func objFunc54() {
        guard let center = self.mapView?.getCenter() else { return }
        
        let pathData = TMapPathData()
        var fflag = 0
        
        pathData.requestFindAroundKeywordPOI(center, keywordName: "LG", radius: 500, count: 20, completion: { (result, error)->Void in
            if let result = result {
                DispatchQueue.main.async {
                    for poi in result {
                        if fflag == 0{
                            if poi.name != self.landMark{
                                self.around.text = poi.name
                                self.landMark = poi.name
                                print("--------------------")
                                print(poi.name)
                            }
                            fflag = 1
                        }
                    }
                }
            }
        })
    }
    
    // 경로탐색
    public func objfunc56(){
        let pathData = TMapPathData()
        self.mapView?.trackinMode = TrackingMode.followWithHeading
        pathData.requestFindAllPOI(self.searchText.text!, count: 20) { (result, error)->Void in
            if let result = result {
                DispatchQueue.main.async {
                    for poi in result {
                        if self.flag2 == false{
                            self.endPointLocation = poi.coordinate
                            self.flag2 = true
                        }
                    }
                }
            }
        }
    }
    
    public func objFunc57() {
        for marker in self.markers {
            marker.map = nil
        }
        self.markers.removeAll()
        for polyline in self.polylines {
            polyline.map = nil
        }
        self.polylines.removeAll()
        
        let start = self.mapView?.getCenter()
        self.mapView?.isRotationEnable = true
        
        let pathData = TMapPathData()
        let startPoint = CLLocationCoordinate2D(latitude: start!.latitude, longitude: start!.longitude) //한양대
        let endPoint = CLLocationCoordinate2D(latitude: self.endPointLocation.latitude, longitude: self.endPointLocation.longitude) //오토웨이타워
        
        pathData.findPathDataWithType(.PEDESTRIAN_PATH, startPoint: startPoint, endPoint: endPoint){ (result, error)->Void in
            if let polyline = result {
                DispatchQueue.main.async {
                    /*let marker1 = TMapMarker(position: startPoint)
                     marker1.map = self.mapView
                     marker1.title = "출발지"
                     self.markers.append(marker1)
                     
                     let marker2 = TMapMarker(position: endPoint)
                     marker2.map = self.mapView
                     marker2.title = "목적지"
                     self.markers.append(marker2)*/
                    
                    polyline.map = self.mapView
                    self.polylines.append(polyline)
                }
            }
            self.path = result?.path
            //self.count = self.path.count
            self.flag = true
            for x in self.path{
                print("--------------\(self.count)----------------")
                print(x)
                self.count += 1
            }
            let d = sqrt(pow(self.path[0].latitude - self.path[1].latitude, 2) + pow(self.path[0].longitude - self.path[1].longitude, 2))
            //let x = fabs(self.path[0].latitude - self.path[1].latitude)
            let y = fabs(self.path[0].longitude - self.path[1].longitude)
            self.exAngle = asin(y/d) * 180 / Double.pi
            //print(self.exAngle)
        }
    }
    
    
    // 사용자 경로 추적
    public func objFunc_userLoc() {
        //let userRef = self.ref.child("\(userID)").child("\(Firecount)")
        //let userRef = self.ref.child("\(userID)/\(Firecount)")
        
        let userIDref = self.ref.child("\(userID)")
        userIDref.observeSingleEvent(of: .value, with: { (snapshot) in
            self.childrenCount = Int(snapshot.childrenCount)
            print("++++++++++++++++++++++++++++++++++++++++++++++++++++++")
            print(self.childrenCount!)
        }) { (error) in
            print(error.localizedDescription)
        }
        
        if self.childrenCount != nil {
            self.pastCoordinate.latitude = 37.556452
            self.pastCoordinate.longitude = 127.045446
            
            for i in 0..<self.childrenCount {
                let count = String(i)
                let userRef = self.ref.child("\(userID)/\(count)")
                userRef.observeSingleEvent(of: .value, with: { (snapshot) in

                    // Get user value
                    let value = snapshot.value as? NSDictionary
                    let location = value?["location"] as? String ?? ""
                    let time = value?["time"] as? String ?? ""
                    let latitude = value?["x"] as! Double
                    let longitude = value?["y"] as! Double

                    self.nextCoordinate.latitude = value?["x"] as! Double
                    self.nextCoordinate.longitude = value?["y"] as! Double
                        
                    print("**********************************")
                    print(location)
                    print(time)
                    print(latitude)
                    print(longitude)
                    print("**********************************")
                  }) { (error) in
                    print(error.localizedDescription)
                }

                let pathData = TMapPathData()
                let startPoint = CLLocationCoordinate2D(latitude: self.pastCoordinate.latitude, longitude: self.pastCoordinate.longitude) //한양대
                let endPoint = CLLocationCoordinate2D(latitude: self.nextCoordinate.latitude, longitude: self.nextCoordinate.longitude) //오토웨이타워

                pathData.findPathDataWithType(.PEDESTRIAN_PATH, startPoint: startPoint, endPoint: endPoint){ (result, error)->Void in
                    if let polyline = result {
                        DispatchQueue.main.async {
                            let marker1 = TMapMarker(position: startPoint)
                            marker1.map = self.mapView
                            marker1.title = "\(String(describing: time))"
                            self.markers.append(marker1)

                            let marker2 = TMapMarker(position: endPoint)
                            marker2.map = self.mapView
                            //marker2.title = "\(String(i+1))"
                            self.markers.append(marker2)

                            polyline.map = self.mapView
                            self.polylines.append(polyline)
                            self.mapView?.fitMapBoundsWithPolylines(self.polylines)
                        }
                    }
                }
                self.pastCoordinate.latitude = self.nextCoordinate.latitude
                self.pastCoordinate.longitude = self.nextCoordinate.longitude
            }
        }
    }
}
