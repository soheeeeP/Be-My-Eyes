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
//import CoreLocation

class mapContainerView: UIViewController, TMapViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet var mapContainerView:UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchText: UITextField!
    
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
    
    @IBOutlet weak var output1: UITextField!
    @IBOutlet weak var output2: UITextField!
    @IBOutlet weak var output3: UITextField!
    
    
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
            if index == count {
                self.GetDirectionTimer!.invalidate()
                flag = false
                output1.text = ""
                output2.text = ""
            }
            else{
                output1.text = "현재위치" + "  \(currentLocation.latitude)" + "   " + "\(currentLocation.longitude)" + "  " + "\(Double(self.angle!))"
                output2.text = "가야할곳" + "  \(path[index].latitude)" + "   " + "\(path[index].longitude)" + "  " + "\(Double(self.exAngle!))"
             
                if sqrt(pow(currentLocation.latitude - self.path[index].latitude, 2) + pow(currentLocation.longitude - self.path[index].longitude, 2)) < 0.00001 {
                    index += 1
                    if index != count{
                        let d = sqrt(pow(currentLocation.latitude - self.path[index].latitude, 2) + pow(currentLocation.longitude - self.path[index].longitude, 2))
                        let y = fabs(currentLocation.longitude - self.path[index].longitude)
                        let a = asin(y/d) * 180 / Double.pi
                        print(a)
                        if a - self.exAngle > 15 {
                            output3.text = "\(a-self.exAngle)만큼 우회전 \(self.index)"
                            print("\(a-self.exAngle)만큼 우회전 \(self.index)")
                        }
                        else if a - self.exAngle < -15 {
                            output3.text = "\(self.exAngle - a)만큼 좌회전 \(self.index)"
                            print("\(self.exAngle - a)만큼 좌회전 \(self.index)")
                        }
                        else{
                            output3.text = "\(fabs(self.exAngle - a))만큼 직진 \(self.index)"
                            print("\(self.exAngle - a)만큼 직진 \(self.index)")
                        }
                        //print("\(Double(self.exAngle))   \(a)")
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
    
    // Go back
    @IBAction func GoBack(_ sender: Any) {
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
}
