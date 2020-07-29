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
    var matchingItems: [MKMapItem] = [MKMapItem]()
    var startLocation: CLLocationCoordinate2D!
    var locationManager: CLLocationManager!
    var path: [CLLocationCoordinate2D]!
    var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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

    // get direoction
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.startLocation = locValue
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
        self.performSearch()
    }
    func performSearch() {
        // 배열 값 삭제
        matchingItems.removeAll()
        let request = MKLocalSearch.Request()
        // 텍스트 필드의 값으로 초기화된 MKLocalSearchRequest 인스턴스를 생성
        request.naturalLanguageQuery = searchText.text
        // 검색 요청 인스턴스에 대한 참조체로 초기화
        let search = MKLocalSearch(request: request)
        // MKLocalSearchCompletionHandler 메서드가 호출되면서 검색이 시작
        search.start(completionHandler: {(response: MKLocalSearch.Response!, error: Error!) in
            if error != nil {
                print("Error occured in search: \(error.localizedDescription)")
            } else if response.mapItems.count == 0 {
                print("No matches found")
            } else {
                print("Matches found")
                // 일치된 값이 있다면 일치된 위치에 대한 mapItem 인스턴스의 배열을 가지고 mapItem 속성에 접근한다.
                for item in response.mapItems as [MKMapItem] {
                    if item.name != nil {
                        print("Name = \(item.name!)")
                    }
                    if item.phoneNumber != nil {
                        print("Phone = \(item.phoneNumber!)")
                    }
                    
                    self.matchingItems.append(item as MKMapItem)
                    print("Matching items = \(self.matchingItems.count)")
                    // 맵에 표시할 어노테이션 생성
                }
            }
        })
    }
    
    // Go back
    @IBAction func GoBack(_ sender: Any) {
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
        self.mapView?.heading = 180
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
    public func objFunc57() {
        for marker in self.markers {
            marker.map = nil
        }
        self.markers.removeAll()
        for polyline in self.polylines {
            polyline.map = nil
        }
        self.polylines.removeAll()
     
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        let pathData = TMapPathData()
        let startPoint = CLLocationCoordinate2D(latitude: self.startLocation.latitude, longitude: self.startLocation.longitude) //한양대
        let endPoint = CLLocationCoordinate2D(latitude: self.matchingItems[0].placemark.coordinate.latitude, longitude: self.matchingItems[0].placemark.coordinate.longitude) //오토웨이타워
        self.mapView?.setCenter(startPoint)
        
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
                    //self.mapView?.fitMapBoundsWithPolylines(self.polylines)
                }
            }
            self.path = result?.path
            for x in self.path{
                print("------------" + "\(self.count)" + "-----------------")
                print(x)
                self.count += 1
            }
        }
    }
}
