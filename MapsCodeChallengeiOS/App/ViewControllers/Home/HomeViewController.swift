//
//  HomeViewController.swift
//  MapsCodeChallengeiOS
//
//  Created by Cris on 8/19/19.
//  Copyright © 2019 Cris. All rights reserved.
//

import UIKit
import GoogleMaps
import FloatingPanel
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

class HomeViewController: UIViewController {
    
    private struct Constants {
        static let googleMapStyleFile = "google_maps_style"
        static let googleMapStyleExtension = "json"
        static let mapZoom: Float = 20
        static let markerInfoViewHeight: CGFloat = 128
        static let markerAnimationDuration: CGFloat = 0.5
        
        struct Navigation {
            static let navLeftUserImageName = "nav_user_img"
            static let navLeftShareImageName = "nav_share_img"
            static let navRightNotificationImageName = "nav_notification"
            static let navRightCloseImageName = "nav_close_img"
        }
    }
    
    private let locationManager = CLLocationManager()
    private let placeManager = PlaceApiManager()
    
    var cardDetailViewController: CardDetailViewController?
    var floatingPanelController: FloatingPanelController?
    
    private var selectedMarker: GMSMarker?
    private var previousMarkerImage: UIImageView?
    private var isMarkerSelected: Bool = false {
        didSet {
            setupNavigationIcons()
        }
    }
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet weak var leftNavButton: UIButton!
    @IBOutlet weak var rightNavButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        setupMapStyle()
        setupFloatingView()
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
    
    @IBAction func didTapNavigationRightButton(_ sender: Any) {
        if isMarkerSelected {
            isMarkerSelected = false
            selectedMarker?.iconView = previousMarkerImage
            selectedMarker = nil
            floatingPanelController?.removePanelFromParent(animated: true)
        }
    }
}

extension HomeViewController {
    
    fileprivate func setupMapStyle() {
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
    
    fileprivate func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    fileprivate func setupFloatingView() {
        floatingPanelController = FloatingPanelController()
        floatingPanelController?.delegate = self
        floatingPanelController?.surfaceView.backgroundColor = .clear
        
        cardDetailViewController = CardDetailViewController(nibName: String(describing: CardDetailViewController.self), bundle: nil)
        floatingPanelController?.set(contentViewController: cardDetailViewController)
        
        floatingPanelController?.surfaceView.cornerRadius = 6.0
        floatingPanelController?.surfaceView.shadowHidden = false
    }
    
    fileprivate func setupNavigationIcons() {
        let leftImageName = isMarkerSelected ? Constants.Navigation.navLeftShareImageName : Constants.Navigation.navLeftUserImageName
        let rightImageName = isMarkerSelected ? Constants.Navigation.navRightCloseImageName : Constants.Navigation.navRightNotificationImageName
        leftNavButton.setImage(UIImage(named: leftImageName), for: .normal)
        rightNavButton.setImage(UIImage(named: rightImageName), for: .normal)
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


extension HomeViewController: CLLocationManagerDelegate {
    
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

extension HomeViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        isMarkerSelected = true
        selectedMarker = marker
        previousMarkerImage = marker.iconView as? UIImageView
        
        marker.iconView = UIImageView(image: UIImage(named: "selected_marker_img"))
        floatingPanelController?.addPanel(toParent: self, belowView: nil, animated: true)
        return true
    }
}

extension HomeViewController: FloatingPanelControllerDelegate {
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return CustomFloatingPanelLayout()
    }
    
    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {
        if targetPosition == .full {
            
        }
    }
}

class CustomFloatingPanelLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .half
    }
    
    public var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .half]
    }
    
    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 150.0
        case .half: return 200.0
        default: return nil
        }
    }
}
