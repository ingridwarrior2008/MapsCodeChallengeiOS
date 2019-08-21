//
//  PlaceApiManager.swift
//  MapsCodeChallengeiOS
//
//  Created by Cris on 8/19/19.
//  Copyright © 2019 Cris. All rights reserved.
//

import UIKit
import GoogleMaps

typealias Completion = ([String: Any]?) -> ()

class PlaceApiManager {
    
    struct Constants {
        static let googlePlaceAPIKey = "AIzaSyB1wguza1Yi5u17xzRIPbM1J8D2aIP4D7g"
        static let googleNearPlaceURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        static let radius = 70
    }

    func loadNearPlace(location: CLLocationCoordinate2D, completion: @escaping Completion) {
        let baseURL = Constants.googleNearPlaceURL + "?location=\(location.latitude),\(location.longitude)&radius=\(Constants.radius)&key=\(Constants.googlePlaceAPIKey)"
        guard let URL = URL(string: baseURL) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: URL) { (data, response, error) in
            guard let resultData = data else {
                completion(nil)
                return
            }
            
            do {
                let result = try JSONSerialization.jsonObject(with: resultData, options: .mutableContainers) as? [String: Any]
                 completion(result)
            } catch {
                completion(nil)
            }
            
        }.resume()
    }
}
