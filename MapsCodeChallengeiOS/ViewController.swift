//
//  ViewController.swift
//  MapsCodeChallengeiOS
//
//  Created by Cris on 8/19/19.
//  Copyright © 2019 Cris. All rights reserved.
//

import UIKit
import GoogleMaps
import os.log

enum PlaceMarker: String {
    case alert = "market_alert_img"
    case police = "market_police_img"
    case minorAlert = "market_alertminor_img"
    
    static func radomMarker() -> PlaceMarker {
        let markers: [PlaceMarker] = [.alert, .police, .minorAlert]
        let index = Int(arc4random()) % markers.count
        return markers[index]
    }
}

class ViewController: UIViewController {
    
    private struct Constants {
        static let googleMapStyleFile = "google_maps_style"
        static let googleMapStyleExtension = "json"
        static let mapZoom: Float = 20
        static let markerInfoViewHeight: CGFloat = 128
        static let markerAnimationDuration: CGFloat = 0.5
    }
    
    private let locationManager = CLLocationManager()
    private let placeManager = PlaceApiManager()
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet weak var markerInfoHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        setupMapStyle()
        setupLocationManager()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func didTapArroundMe(_ sender: Any) {
        
        guard let userLocation = mapView.myLocation?.coordinate else {
            return
        }
        
        let camera = GMSCameraPosition(target: userLocation, zoom: Constants.mapZoom)
        mapView.animate(to: camera)
        
        findNearPlaceArroundMe()
    }
}

extension ViewController {
    
    func setupMapStyle() {
        guard let styleURL = Bundle.main.url(forResource: Constants.googleMapStyleFile, withExtension: Constants.googleMapStyleExtension) else {
            os_log("Unable to find google map style file", log: OSLog.default, type: .debug)
            return
        }
        
        do {
            mapView?.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
        } catch {
            os_log("Unable set the map style", log: OSLog.default, type: .error)
        }
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func findNearPlaceArroundMe() {
        guard let userLocation = mapView.myLocation?.coordinate else {
            return
        }
        placeManager.loadNearPlace(location: userLocation) { (result) in
            if let resultJson = result, let results = resultJson["results"] as? [[String: Any]] {
                for resultItems in results {
                    for values in resultItems {
                        if let geometry = values.value as? [String: Any],
                            let location = geometry["location"] as? [String: Any],
                            let latitude = location["lat"] as? Double,
                            let longitude = location["lng"] as? Double {
                            
                            DispatchQueue.main.async { [weak self] in
                                self?.setupMarker(lat: latitude, lng: longitude)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setupMarker(lat: Double, lng: Double) {
        let markerImageName = PlaceMarker.radomMarker().rawValue
        let markerImage = UIImage(named: markerImageName)
        let markerImageView = UIImageView(image: markerImage)
        
        let position = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let marker = GMSMarker(position: position)
        marker.iconView = markerImageView
        marker.map = mapView
    }
}


extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else { return }
        
        locationManager.startUpdatingLocation()
        mapView.isMyLocationEnabled = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.first else {
            os_log("Unable to find locations", log: OSLog.default, type: .debug)
            return
        }
        
        mapView.camera = GMSCameraPosition(target: currentLocation.coordinate, zoom: Constants.mapZoom)
    }
}

extension ViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        markerInfoHeightConstraint.constant = Constants.markerInfoViewHeight
        
        UIView.animate(withDuration: TimeInterval(Constants.markerAnimationDuration), animations: {
            self.view.layoutIfNeeded()
        })
        return true
    }
}
