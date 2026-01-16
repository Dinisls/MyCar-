//
//  UserAnnotation.swift
//  MyCar
//
//  Created by Dinis Santos on 16/01/2026.
//


import SwiftUI
import MapKit

struct UserAnnotation: MapContent {
    var coordinate: CLLocationCoordinate2D?
    
    var body: some MapContent {
        if let coordinate = coordinate {
            Annotation("A minha localização", coordinate: coordinate) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .shadow(radius: 3)
                    
                    Circle()
                        .fill(.blue)
                        .frame(width: 20, height: 20)
                }
            }
        }
    }
}