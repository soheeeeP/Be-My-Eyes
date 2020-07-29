//
//  mapContainerView.swift
//  Be-My-Eyes
//
//  Created by 방윤 on 2020/07/05.
//  Copyright © 2020 Be-My-Eyes. All rights reserved.
//

import UIKit
import TMapSDK
//import CoreLocation

class mapContainerView: UIViewController, TMapViewDelegate {
    @IBOutlet var mapContainerView:UIView!
    @IBOutlet var logLabel:UILabel!
    @IBOutlet var menuConstraints:NSLayoutConstraint?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pt2View:UIView!

    var mapView:TMapView?

    var leftArray:Array<LeftMenuData>?
    
    let mPosition: CLLocationCoordinate2D = CLLocationCoordinate2D.init(latitude: 37.570841, longitude: 126.985302)

    var texts:Array<TMapText> = []
    var markers:Array<TMapMarker> = []
    var circles:Array<TMapCircle> = []
    var rectangles:Array<TMapRectangle> = []
    var polylines:Array<TMapPolyline> = []
    var polygons:Array<TMapPolygon> = []
    
    var isPublicTrasit = false
    var isPublicTrasit2 = false
    var ptMarkers:Array<TMapMarker> = []
    var ptCircle:TMapCircle?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.mapView = TMapView(frame: mapContainerView.frame)
        self.mapView?.delegate = self
        self.mapView?.setApiKey("l7xxf8cfdf8de7494065a7a4f2d71d12a412")

        mapContainerView.addSubview(self.mapView!)
        
        //setting leftmenu
        self.initTableViewData()
    }

    @IBAction func touchMenuButton(_ sender:AnyObject) {
        menuConstraints?.constant = 0
        self.initTableViewData()
    }

    //alert view
    public func simpleAlertView(_ message: String, title: String, view:UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "확인", style: UIAlertAction.Style.default, handler: nil))
        view.present(alert, animated: true, completion: nil)
    }

    func onOffString(_ baseStr:String, onOff:Bool)->String {
        if onOff {
            return String(format: "%@ off", baseStr)
        }
        else {
            return String(format: "%@ on", baseStr)
        }
    }
    
    func clearMarkers() {
        for marker in self.markers {
            marker.map = nil
        }
        self.markers.removeAll()
    }
    
    func clearPolylines() {
        for polyline in self.polylines {
            polyline.map = nil
        }
        self.polylines.removeAll()
    }
    
    func initTableViewData() {
        self.leftArray = Array()
      
        self.leftArray?.append(LeftMenuData(title: "초기화", onClick: initMapView))
        
        if let mapView = self.mapView {
            // 기본 기능
            self.leftArray?.append(LeftMenuData(title: "화면이동", onClick: basicFunc001))
            self.leftArray?.append(LeftMenuData(title: "줌레벨및화면이동", onClick: basicFunc002))
            self.leftArray?.append(LeftMenuData(title: "11레벨 선택", onClick: basicFunc003))
            self.leftArray?.append(LeftMenuData(title: "확대", onClick: basicFunc004))
            self.leftArray?.append(LeftMenuData(title: "축소", onClick: basicFunc005))
            self.leftArray?.append(LeftMenuData(title: "화면중심좌표표출", onClick: onClickCenterPosition))
            self.leftArray?.append(LeftMenuData(title: self.onOffString("지도 회전", onOff: mapView.isRotationEnable), onClick: basicFunc011))
            self.leftArray?.append(LeftMenuData(title: "현재지도방향", onClick: basicFunc012))
            self.leftArray?.append(LeftMenuData(title: "지도방향설정", onClick: basicFunc013))
            self.leftArray?.append(LeftMenuData(title: self.onOffString("패닝 설정", onOff: mapView.isPanningEnable), onClick: basicFunc014))
            self.leftArray?.append(LeftMenuData(title: self.onOffString("확대/축소 설정", onOff: mapView.isZoomEnable), onClick: basicFunc015))
            self.leftArray?.append(LeftMenuData(title: "지도 캡쳐", onClick: onClickCapture))
            
            // 마커
            self.leftArray?.append(LeftMenuData(title: "마커 추가", onClick: objFunc01))
            self.leftArray?.append(LeftMenuData(title: "마커영역 이동", onClick: objFunc02))
            self.leftArray?.append(LeftMenuData(title: "마커 제거", onClick: objFunc03))
            
            // 원
            self.leftArray?.append(LeftMenuData(title: "원 추가", onClick: objFunc11))
            self.leftArray?.append(LeftMenuData(title: "원영역 이동", onClick: objFunc12))
            self.leftArray?.append(LeftMenuData(title: "원 제거", onClick: objFunc13))

            // 사각형
            self.leftArray?.append(LeftMenuData(title: "사각형 추가", onClick: objFunc21))
            self.leftArray?.append(LeftMenuData(title: "사각형영역 이동", onClick: objFunc22))
            self.leftArray?.append(LeftMenuData(title: "사각형 제거", onClick: objFunc23))

            // 라인
            self.leftArray?.append(LeftMenuData(title: "라인 추가", onClick: objFunc31))
            self.leftArray?.append(LeftMenuData(title: "라인영역 이동", onClick: objFunc32))
            self.leftArray?.append(LeftMenuData(title: "라인 제거", onClick: objFunc33))

            // 폴리곤
            self.leftArray?.append(LeftMenuData(title: "폴리곤 추가", onClick: objFunc41))
            self.leftArray?.append(LeftMenuData(title: "폴리곤영역 이동", onClick: objFunc42))
            self.leftArray?.append(LeftMenuData(title: "폴리곤 제거", onClick: objFunc43))

            // traffic
            self.leftArray?.append(LeftMenuData(title: self.onOffString("교통정보", onOff: mapView.isTrafficMode), onClick: toggleTrafficMode))
            
            // api
//            self.leftArray?.append(LeftMenuData(title: "자동완성", onClick: objFunc51))
//            self.leftArray?.append(LeftMenuData(title: "BizCategory", onClick: objFunc52))
            self.leftArray?.append(LeftMenuData(title: "POI 검색", onClick: objFunc53))
            self.leftArray?.append(LeftMenuData(title: "POI 주변검색", onClick: objFunc54))
            self.leftArray?.append(LeftMenuData(title: "가까운 POI 검색", onClick: objFunc55))
            self.leftArray?.append(LeftMenuData(title: "리버스 지오코딩", onClick: objFunc56))
            self.leftArray?.append(LeftMenuData(title: "경로탐색", onClick: objFunc57))
            self.leftArray?.append(LeftMenuData(title: "경로탐색(경유지)", onClick: objFunc58))
//            self.leftArray?.append(LeftMenuData(title: "타임머신", onClick: objFunc59))
            self.leftArray?.append(LeftMenuData(title: "경유지 최적화", onClick: objFunc60))
            self.leftArray?.append(LeftMenuData(title: self.onOffString("대중교통 1", onOff: self.isPublicTrasit), onClick: objFunc71))
            self.leftArray?.append(LeftMenuData(title: self.onOffString("대중교통 2", onOff: self.isPublicTrasit2), onClick: objFunc72))
            self.leftArray?.append(LeftMenuData(title: "오버레이 이미지", onClick: objFunc73))
            self.leftArray?.append(LeftMenuData(title: "Tmap 열기", onClick: objFunc74))
        }

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

// MARK: - Map delegate -

extension mapContainerView {
    public func mapViewDidFinishLoadingMap() {
        self.logLabel.text = "지도 로딩 완료"
    }
    
    public func mapViewDidChangeBounds() {
        self.logLabel.text = "지도 영역 변경됨"
    }
    
    func mapView(_ mapView: TMapView, tapOnMarker marker: TMapMarker) {
        self.logLabel.text = "마커 터치됨"
    }
    
    func mapView(_ mapView: TMapView, singleTapOnMap location: CLLocationCoordinate2D) {
        self.logLabel.text = "지도 싱글탭"
        
        if isPublicTrasit {
            let pathData = TMapPathData()
            pathData.requestFindAroundKeywordPOI(location, keywordName: "편의점;한의원", radius: 1, count: 30, completion: { (result, error)->Void in
                if let result = result {
                    DispatchQueue.main.async {
                        for marker in self.ptMarkers {
                            marker.map = nil
                        }
                        self.ptMarkers.removeAll()
                        self.ptCircle?.map = nil
                        let circle = TMapCircle(position: location, radius: 1000)
                        circle.fillColor = .lightGray
                        circle.strokeColor = .lightGray
                        circle.map = self.mapView
                        self.ptCircle = circle
                        
                        for poiItem in result {
                            if let coord = poiItem.coordinate {
                                let marker = TMapMarker(position: coord)
                                self.ptMarkers.append(marker)
                                marker.map = self.mapView
                            }
                        }
                    }
                }
            })
        }
    }
    
    func mapView(_ mapView: TMapView, doubleTapOnMap location: CLLocationCoordinate2D) {
        self.logLabel.text = "지도 더블탭"
    }
    
    func mapView(_ mapView: TMapView, longTapOnMap location: CLLocationCoordinate2D) {
        self.logLabel.text = "지도 롱탭"
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
        mapContainerView.addSubview(self.mapView!)
    }
    //화면이동
    public func basicFunc001(){
        self.mapView?.setCenter(mPosition)
    }
    //줌레벨및화면이동
    public func basicFunc002(){
        self.mapView?.setCenter(mPosition)
        self.mapView?.setZoom(11)
    }
    //11레벨 선택
    public func basicFunc003(){
        self.mapView?.setZoom(11)
    }
    //확대
    public func basicFunc004(){
        var zoom: Int = self.mapView?.getZoom() ?? 0
        zoom = zoom + 1
        self.mapView?.setZoom(zoom)
        simpleAlertView("zoom:\(zoom)" , title: "", view: self)
    }
    //축소
    public func basicFunc005(){
        var zoom: Int =  self.mapView?.getZoom() ?? 0
        zoom = zoom - 1
        self.mapView?.setZoom(zoom)
        simpleAlertView("zoom:\(zoom)" , title: "", view: self)
    }
    //화면중심좌표표출
    public func onClickCenterPosition(){
        let lat: Double = (self.mapView?.getCenter()?.latitude)!
        let lon: Double = (self.mapView?.getCenter()?.longitude)!
        
        simpleAlertView("lat:\(lat) \n lon:\(lon)" , title: "", view: self)
    }
    // 지도 회전 설정
    public func basicFunc011() {
        guard let mapView = self.mapView else { return }
        mapView.isRotationEnable = !mapView.isRotationEnable
    }
    
    // 지도방향
    public func basicFunc012() {
        if let heading = self.mapView?.heading {
            self.simpleAlertView("\(Int(heading))", title: "지도방향", view: self)
        }
    }
    // 지도방향 설정
    public func basicFunc013() {
        self.mapView?.heading = 180
    }
    // 패닝 설정
    public func basicFunc014() {
        guard let mapView = self.mapView else { return }
        mapView.isPanningEnable = !mapView.isPanningEnable
    }
    // 확대축소 설정
    public func basicFunc015() {
        guard let mapView = self.mapView else { return }
        mapView.isZoomEnable = !mapView.isZoomEnable
    }
    // 캡쳐
    public func onClickCapture() {
        self.mapView?.captureMapView()
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
    
    // 원 추가
    public func objFunc11() {
        let position = self.mapView?.getCenter()
        let circle = TMapCircle(position: position!, radius: 100)
        circle.fillColor = .cyan
        circle.strokeColor = .red
        circle.opacity = 0.5
        
        circle.map = self.mapView
        self.circles.append(circle)
    }
    
    // 원 fit
    public func objFunc12() {
        self.mapView?.fitMapBoundsWithCircles(self.circles)
    }

    // 원 제거
    public func objFunc13() {
        for circle in self.circles {
            circle.map = nil
        }
        self.circles.removeAll()
    }
    
    // 사각형 추가
    public func objFunc21() {
        let position = self.mapView?.getCenter()
        let sw = CLLocationCoordinate2D(latitude: position!.latitude - 0.001, longitude: position!.longitude - 0.001)
        let ne = CLLocationCoordinate2D(latitude: position!.latitude + 0.001, longitude: position!.longitude + 0.001)
        let rectangle = TMapRectangle(rectangle: MapBounds(sw: sw, ne: ne))
        rectangle.fillColor = .cyan
        rectangle.strokeColor = .red
        rectangle.opacity = 0.5

        rectangle.map = self.mapView
        self.rectangles.append(rectangle)
    }
    
    // 사각형 fit
    public func objFunc22() {
        self.mapView?.fitMapBoundsWithRectangles(self.rectangles)
    }

    // 사각형 제거
    public func objFunc23() {
        for rectangle in self.rectangles {
            rectangle.map = nil
        }
        self.rectangles.removeAll()
    }

    // 라인 추가
    public func objFunc31() {
        let position = self.mapView?.getCenter()
        
        if let position = position {
            var path = Array<CLLocationCoordinate2D>()
            path.append(CLLocationCoordinate2D(latitude: position.latitude - 0.001, longitude: position.longitude - 0.001))
            path.append(CLLocationCoordinate2D(latitude: position.latitude + 0.001, longitude: position.longitude - 0.0005))
            path.append(CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude))
            path.append(CLLocationCoordinate2D(latitude: position.latitude + 0.001, longitude: position.longitude + 0.0005))
            path.append(CLLocationCoordinate2D(latitude: position.latitude - 0.001, longitude: position.longitude + 0.001))
            
            let polyline = TMapPolyline(coordinates: path)
            polyline.strokeWidth = 4
            polyline.strokeColor = .red
            
            polyline.map = self.mapView
            self.polylines.append(polyline)
        }

    }

    // 라인 fit
    public func objFunc32() {
        self.mapView?.fitMapBoundsWithPolylines(self.polylines)
    }

    // 라인 제거
    public func objFunc33() {
        for polyline in self.polylines {
            polyline.map = nil
        }
        self.polylines.removeAll()
    }

    // 폴리곤 추가
    public func objFunc41() {
        let position = self.mapView?.getCenter()
        
        if let position = position {
            var path = Array<CLLocationCoordinate2D>()
            path.append(CLLocationCoordinate2D(latitude: position.latitude - 0.001, longitude: position.longitude - 0.001))
            path.append(CLLocationCoordinate2D(latitude: position.latitude + 0.001, longitude: position.longitude - 0.0005))
            path.append(CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude))
            path.append(CLLocationCoordinate2D(latitude: position.latitude + 0.001, longitude: position.longitude + 0.0005))
            path.append(CLLocationCoordinate2D(latitude: position.latitude - 0.001, longitude: position.longitude + 0.001))
            
            let polygon = TMapPolygon(coordinates: path)
            polygon.opacity = 0.8
            polygon.fillColor = .brown
            polygon.strokeColor = .red
            
            polygon.map = self.mapView
            self.polygons.append(polygon)
        }

    }

    // 폴리곤 fit
    public func objFunc42() {
        self.mapView?.fitMapBoundsWithPolygons(self.polygons)
    }

    // 폴리곤 제거
    public func objFunc43() {
        for polygon in self.polygons {
            polygon.map = nil
        }
        self.polygons.removeAll()
    }
}

// MARK: - Map api functions -

extension mapContainerView {
    // 교통정보 onoff
    public func toggleTrafficMode() {
        guard let mapView = self.mapView else { return }
        self.mapView?.setTrafficMode(!mapView.isTrafficMode)
    }
    
    // api
    public func objFunc51() {
        let pathData = TMapPathData()
        pathData.autoComplete("sk") { (result, error)->Void in
            for keyword in result {
                print(keyword)
            }
        }
    }
    
    public func objFunc52() {
        let pathData = TMapPathData()
        pathData.getBizCategory(completion: { (result, error)->Void in
            if let result = result {
                for category in result {
                    print(category.middleBizName!)
                }
            }
        })
    }
    
    public func objFunc53() {
        self.clearMarkers()
        self.clearPolylines()

        let pathData = TMapPathData()
        pathData.requestFindAllPOI("sk", count: 20) { (result, error)->Void in
            if let result = result {
                DispatchQueue.main.async {
                    for poi in result {
                        let marker = TMapMarker(position: poi.coordinate!)
                        marker.map = self.mapView
                        marker.title = poi.name
                        self.markers.append(marker)
                        self.mapView?.fitMapBoundsWithMarkers(self.markers)
                    }
                }
            }
        }
    }

    public func objFunc54() {
        guard let center = self.mapView?.getCenter() else { return }
        self.clearMarkers()
        self.clearPolylines()

        let pathData = TMapPathData()
        
        pathData.requestFindAroundKeywordPOI(center, keywordName: "sk", radius: 500, count: 20, completion: { (result, error)->Void in
            if let result = result {
                DispatchQueue.main.async {
                    for poi in result {
                        let marker = TMapMarker(position: poi.coordinate!)
                        marker.map = self.mapView
                        marker.title = poi.name
                        self.markers.append(marker)
//                        self.mapView?.fitMapBoundsWithMarkers(self.markers)
                    }
                }
            }
        })
    }

    public func objFunc55() {
        guard let center = self.mapView?.getCenter() else { return }
        self.clearMarkers()
        self.clearPolylines()

        let pathData = TMapPathData()
        
        pathData.requestFindNearestPOI(center, radius: 500, completion: {(result, error)->Void in
            if let result = result {
                DispatchQueue.main.async {
                    for poi in result {
                        let marker = TMapMarker(position: poi.coordinate!)
                        marker.map = self.mapView
                        marker.title = poi.name
                        self.markers.append(marker)
                        //                        self.mapView?.fitMapBoundsWithMarkers(self.markers)
                    }
                }
            }
        })
    }
    
    public func objFunc56() {
        guard let center = self.mapView?.getCenter() else { return }
        self.clearMarkers()
        self.clearPolylines()

        let pathData = TMapPathData()
        
        pathData.reverseGeocoding(center, addressType: "A02") { (result, error)->Void in
            if let result = result {
                DispatchQueue.main.async {
                    let marker = TMapMarker(position: center)
                    marker.map = self.mapView
                    marker.title = result["fullAddress"] as? String
                    self.markers.append(marker)
                }
            }
        }
    }
    
    // 경로탐색
    public func objFunc57() {
        self.clearMarkers()
        self.clearPolylines()
        
        let pathData = TMapPathData()
        let startPoint = CLLocationCoordinate2D(latitude: 37.5508, longitude: 126.9435) //한양대
        let endPoint = CLLocationCoordinate2D(latitude: 37.549873, longitude: 126.943924) //오토웨이타워

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
                    self.mapView?.fitMapBoundsWithPolylines(self.polylines)
                }
            }
        }
    }

    // 경로탐색(경유지)
    public func objFunc58() {
        self.clearMarkers()
        self.clearPolylines()
        
        let pathData = TMapPathData()
        let startPoint = CLLocationCoordinate2D(latitude: 37.566567, longitude: 126.985038)
        let endPoint = CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318)
        let via1Point = CLLocationCoordinate2D(latitude: 37.557822, longitude: 126.925119)
        let via2Point = CLLocationCoordinate2D(latitude: 37.510537, longitude: 127.062002)

        pathData.findPathDataWithType(.CAR_PATH, startPoint: startPoint, endPoint: endPoint, passPoints: [via1Point, via2Point], searchOption: 1) { (result, error)->Void in
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
                    self.mapView?.fitMapBoundsWithPolylines(self.polylines)
                }
            }
        }
    }

    // 타임머신
    public func objFunc59() {
        self.clearMarkers()
        self.clearPolylines()
        
        let pathData = TMapPathData()
        let startPoint = CLLocationCoordinate2D(latitude: 37.566567, longitude: 126.985038)
        let endPoint = CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318)
//        let via1Point = CLLocationCoordinate2D(latitude: 37.557822, longitude: 126.925119)
//        let via2Point = CLLocationCoordinate2D(latitude: 37.510537, longitude: 127.062002)

        pathData.findTimeMachineCar(startPoint: startPoint, endPoint: endPoint, isStartTime: true, time: Date(), wayPoints: nil) { (result, error)->Void in
        }
    }
    
    // 경유지 최적화
    public func objFunc60() {
        self.clearMarkers()
        self.clearPolylines()
        
        let pathData = TMapPathData()
        let startPoint = CLLocationCoordinate2D(latitude: 37.566567, longitude: 126.985038)
        let endPoint = CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318)
        let via1Point = CLLocationCoordinate2D(latitude: 37.557822, longitude: 126.925119)
        let via2Point = CLLocationCoordinate2D(latitude: 37.510537, longitude: 127.062002)

        pathData.findMultiPathData(startPoint: startPoint, endPoint: endPoint, passPoints: [via1Point, via2Point], searchOption: 1) { (result, error)->Void in
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
                    self.mapView?.fitMapBoundsWithPolylines(self.polylines)
                }
            }
        }
    }
    
    // 대중교통1
    public func objFunc71() {
        if self.isPublicTrasit {
            for marker in self.ptMarkers {
                marker.map = nil
            }
            self.ptMarkers.removeAll()
            self.ptCircle?.map = nil
        }
        self.isPublicTrasit = !self.isPublicTrasit
    }

    // 대중교통2
    public func objFunc72() {
        self.clearMarkers()
        self.clearPolylines()
        
        if self.isPublicTrasit2 {
            self.pt2View.isHidden = true
        }
        self.isPublicTrasit2 = !self.isPublicTrasit2
        
        if self.isPublicTrasit2 == false {
            return
        }

        let pathData = TMapPathData()
        let startPoint = CLLocationCoordinate2D(latitude: 37.5562607, longitude: 127.0432408) //한양대
        let endPoint = CLLocationCoordinate2D(latitude: 37.5061729, longitude: 127.06173) //오토웨이타워
        let via1Point = CLLocationCoordinate2D(latitude: 37.557822, longitude: 126.925119)
        let via2Point = CLLocationCoordinate2D(latitude: 37.510537, longitude: 127.062002)

        pathData.findPathDataWithType(.CAR_PATH, startPoint: startPoint, endPoint: endPoint, passPoints: [via1Point, via2Point], searchOption: 1) { (result, error)->Void in
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

                    let marker3 = TMapMarker(position: via1Point)
                    marker3.map = self.mapView
                    self.markers.append(marker3)

                    let marker4 = TMapMarker(position: via2Point)
                    marker4.map = self.mapView
                    self.markers.append(marker4)

                    polyline.map = self.mapView
                    self.polylines.append(polyline)
                    self.mapView?.fitMapBoundsWithPolylines(self.polylines)
                    
                    self.pt2View.isHidden = false
                }
            }
        }

    }
    
    public func objFunc73() {
        let bounds = MapBounds(sw: CLLocationCoordinate2D(latitude: 37.566115, longitude: 126.977378), ne: CLLocationCoordinate2D(latitude: 37.566997, longitude: 126.979071))
        let cityhallImage = UIImage(named: "cityhall")
        let groundImage = TMapOverlayImage(bounds: bounds, image: cityhallImage!)
        groundImage.map = self.mapView

        self.mapView?.fitBounds(bounds)
    }
    
    // TMapApp 연동 길안내
    public func objFunc74() {
        TMapApi.invokeRoute("sample", coordinate: mPosition)
    }
    
    @IBAction func touchPtButtoms(_ sender:AnyObject) {
        switch sender.tag {
        case 1:
            self.mapView?.setCenter(CLLocationCoordinate2D(latitude: 37.566567, longitude: 126.985038))
            break
        case 2:
            self.mapView?.setCenter(CLLocationCoordinate2D(latitude: 37.557822, longitude: 126.925119))
            break
        case 3:
            self.mapView?.setCenter(CLLocationCoordinate2D(latitude: 37.510537, longitude: 127.062002))
            break
        case 4:
            self.mapView?.setCenter(CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318))
            break
        default:
            break
        }
    }
}
