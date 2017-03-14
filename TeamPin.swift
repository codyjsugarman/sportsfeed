//
//  TeamPin.swift
//  Newsboard
//
//

import Foundation
import MapKit

class TeamPin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}