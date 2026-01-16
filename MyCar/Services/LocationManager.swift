import Foundation
import CoreLocation
import MapKit
import SwiftUI

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    // Estado atual
    var currentSpeed: Double = 0.0 // m/s
    var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    // Dados da sessão de gravação
    var routePoints: [TripPoint] = []
    var totalDistance: Double = 0.0
    private var lastLocation: CLLocation?
    
    // Controlo de gravação
    var isRecording = false
    
    override init() {
        super.init()
        manager.delegate = self
        
        // --- CONFIGURAÇÃO CRÍTICA PARA BACKGROUND ---
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        
        // Permite que o GPS funcione com a app minimizada
        manager.allowsBackgroundLocationUpdates = true
        
        // Impede que o iOS pause o GPS se parares num semáforo
        manager.pausesLocationUpdatesAutomatically = false
        
        // Pede autorização total ("Sempre" ou "Durante a utilização" com background ativo)
        manager.requestAlwaysAuthorization()
        
        manager.startUpdatingLocation()
    }
    
    func startRecording() {
        routePoints = []
        totalDistance = 0
        lastLocation = nil
        isRecording = true
    }
    
    func stopRecording() {
        isRecording = false
        currentSpeed = 0
    }
    
    // MARK: - Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Ignora pontos muito antigos (ajuda na precisão inicial)
        if location.timestamp.timeIntervalSinceNow < -5 { return }
        // Ignora pontos com precisão muito má (acima de 50 metros)
        if location.horizontalAccuracy > 50 { return }
        
        // Atualiza a UI
        self.currentSpeed = max(0, location.speed)
        
        withAnimation {
            self.currentRegion.center = location.coordinate
        }
        
        // Gravação
        if isRecording {
            let newPoint = TripPoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                speed: location.speed,
                timestamp: Date()
            )
            routePoints.append(newPoint)
            
            if let last = lastLocation {
                totalDistance += location.distance(from: last)
            }
            lastLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Erro GPS: \(error.localizedDescription)")
    }
}
