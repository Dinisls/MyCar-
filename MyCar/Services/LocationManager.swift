import Foundation
import CoreLocation
import MapKit // <--- IMPORTANTE: Necessário para MKCoordinateRegion

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    // Dados da Rota
    var routePoints: [RoutePoint] = []
    
    // Dados em Tempo Real
    var currentSpeed: Double = 0.0
    var totalDistance: Double = 0.0
    
    // --- CORREÇÃO DO ERRO ---
    // Região do mapa para o SwiftUI seguir a localização
    var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393), // Default: Lisboa
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    private var lastLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.allowsBackgroundLocationUpdates = true // Importante para tracking em background
        manager.pausesLocationUpdatesAutomatically = false
        manager.requestWhenInUseAuthorization()
    }
    
    func startRecording() {
        routePoints = []
        totalDistance = 0
        lastLocation = nil
        manager.startUpdatingLocation()
    }
    
    func stopRecording() {
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 1. Atualiza a Região do Mapa (Onde a câmara aponta)
        currentRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        
        // 2. Calcula a distância e velocidade
        if let last = lastLocation {
            totalDistance += location.distance(from: last)
        }
        lastLocation = location
        currentSpeed = max(location.speed, 0) // Evita velocidades negativas
        
        // 3. Guarda o ponto na rota
        let newPoint = RoutePoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp,
            speed: max(location.speed, 0)
        )
        
        routePoints.append(newPoint)
    }
}
