//
//  TripPoint.swift
//  MyCar
//
//  Created by Dinis Santos on 16/01/2026.
//


import Foundation
import CoreLocation

struct TripPoint: Codable, Identifiable {
    var id = UUID()
    let latitude: Double
    let longitude: Double
    let speed: Double // em m/s
    let timestamp: Date
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}