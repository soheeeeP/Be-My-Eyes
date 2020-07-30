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
    var circles:Array<TMapCircle> = []
    var rectangles:Array<TMapRectangle> = []
    var polylines:Array<TMapPolyline> = []
    var polygons:Array<TMapPolygon> = []
    
    // 추가
    var startPointLocation: CLLocationCoordinate2D!
    var endPointLocation: CLLocationCoordinate2D!
    var currentLocation: CLLocationCoordinate2D!
    var locationManager: CLLocationManager!
    var start: CLLocationCoordinate2D!
    var path: [CLLocationCoordinate2D]!
    var count = 0
    var GetDirectionTimer: Timer?
    var flag = false
    var index = 0
    var flag2 = false
    var directionCode = [["직진", "좌회전", "우회전", "후진"], ["우회전", "직진", "후진", "좌회전"], ["좌회전", "후진", "직진", "우회전"], ["후진", "우회전", "좌회전", "직진"]]
    var directionIndex = 0
    var angle: Double!
    var exAngle: Double!
    
    @IBOutlet weak var output1: UITextField!
    @IBOutlet weak var output2: UITextField!
    @IBOutlet weak var output3: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        GetDirectionTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(Move), userInfo: nil, repeats: true)
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
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
                
                if fabs(currentLocation.latitude - self.path[index].latitude) > 0.00001 && fabs(currentLocation.longitude - self.path[index].longitude) > 0.000001 {
                    index += 1
                    
                    if index != count{
                        let x = fabs(currentLocation.latitude - self.path[index].latitude)
                        let y = fabs(currentLocation.longitude - self.path[index].longitude)
                        let a = atan(x/y)
                        if a - self.exAngle > 0 {
                            output3.text = "\(a-self.exAngle)만큼 우회전 \(self.index)"
                            print("\(a-self.exAngle)만큼 우회전 \(self.index)")
                        }
                        else if a - self.exAngle < 0 {
                            output3.text = "\(self.exAngle - a)만큼 좌회전 \(self.index)"
                            print("\(self.exAngle - a)만큼 좌회전 \(self.index)")
                        }
                        self.exAngle = a
                        
                    }
                }
            }
        }
    }
    
    // get direoction
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.startPointLocation = locValue
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code == .denied{
            manager.stopUpdatingLocation()
            manager.stopMonitoringSignificantLocationChanges()
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
     
        self.mapView?.setCenter(self.startPointLocation)
        self.mapView?.isRotationEnable = true
        self.mapView?.trackinMode = TrackingMode.followWithHeading

        let pathData = TMapPathData()
        let startPoint = CLLocationCoordinate2D(latitude: self.startPointLocation!.latitude, longitude: self.startPointLocation!.longitude) //한양대
        let endPoint = CLLocationCoordinate2D(latitude: self.endPointLocation.latitude, longitude: self.endPointLocation.longitude) //오토웨이타워
        
        pathData.findPathDataWithType(.PEDESTRIAN_PATH, startPoint: startPoint, endPoint: endPoint){ (result, error)->Void in
            if let polyline = result {
                DispatchQueue.main.async {
                    let marker1 = TMapMarker(position: startPoint)
                    marker1.map = self.mapView
                    marker1.title = "출발지"
                    self.markers.append(marker1)

                    let marker2 = TMapMarker(position: endPoint)
                    marker2.map = self.mapView
                    marker2.title = "목적지"
                    self.markers.append(marker2)

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
            let x = fabs(self.path[0].latitude - self.path[1].latitude)
            let y = fabs(self.path[0].longitude - self.path[1].longitude)
            self.exAngle = atan(x/y)
            print(self.exAngle)
        }
    }
}
