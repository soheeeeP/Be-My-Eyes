//
//  MapViewController.swift
//  Be-My-Eyes
//
//  Created by 박소희 on 2020/07/06.
//  Copyright © 2020 Be-My-Eyes. All rights reserved.
//

import UIKit
import CoreLocation

var markerList = [MTMapPOIItem] ()

class MapViewController: UIViewController, MTMapViewDelegate, CLLocationManagerDelegate {

    var mapView: MTMapView?
    var mapPoint: MTMapPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView = MTMapView(frame: self.view.bounds)
                    
        // set center point to 서강대학교
        mapPoint = MTMapPoint.init(geoCoord: MTMapPointGeo.init(latitude: 37.550950, longitude: 126.941017))
        mapView?.setMapCenter(mapPoint, animated: true)
        

        markerList.append(poiItem(name: "Start", latitude: 37.550950, longitude: 126.941017))
        
        mapView?.addPOIItems(markerList)
        mapView?.fitAreaToShowAllPOIItems()

        
        if let mapView = mapView {
            mapView.delegate = self
            mapView.baseMapType = .standard
            mapView.showCurrentLocationMarker = true
            self.view.addSubview(mapView)
            self.view.sendSubviewToBack(mapView)
            print("map view")
            
        }
        
    }
    
    func circle() -> MTMapCircle{
        
        let circ = MTMapCircle()
        circ.circleCenterPoint = MTMapPoint(geoCoord: MTMapPointGeo(latitude: 37.550950, longitude: 126.941017))
        
        circ.circleRadius = 500.0
        circ.circleLineColor = UIColor.red
        circ.circleLineWidth = 5
        circ.circleFillColor = UIColor.yellow
        circ.tag = 1
        
        return circ
    }
    
    @IBAction func onCurrentLocationClick(_ sender: Any) {
        print("current location button")
    }
    @IBAction func goToTTS(_ sender: UIButton){
        performSegue(withIdentifier: "unwindToVC1", sender: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // 여기서 map view가 고쳐질 때마다 새로 화면 load
    }
    
    func poiItem(name: String, latitude: Double, longitude: Double) -> MTMapPOIItem {
         let item = MTMapPOIItem()
         item.itemName = name
         item.markerType = .redPin
         item.markerSelectedType = .redPin
         item.mapPoint = MTMapPoint(geoCoord: .init(latitude: latitude, longitude: longitude))
         item.showAnimationType = .noAnimation
         item.customImageAnchorPointOffset = .init(offsetX: 30, offsetY: 0)    // 마커 위치
         
         return item
     }

}

