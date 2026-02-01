import Foundation
import CoreLocation
import MapKit

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    // Dados da Rota
    var routePoints: [RoutePoint] = []
    
    // Dados em Tempo Real
    var currentSpeed: Double = 0.0
    var totalDistance: Double = 0.0
    
    // ESTADO DE PAUSA
    var isPaused = false
    
    // Região do mapa
    var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    private var lastLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.requestWhenInUseAuthorization()
    }
    
    func startRecording() {
        routePoints = []
        totalDistance = 0
        lastLocation = nil
        isPaused = false // Reinicia pausa
        manager.startUpdatingLocation()
    }
    
    func stopRecording() {
        manager.stopUpdatingLocation()
        isPaused = false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 1. Atualiza a Região do Mapa (SEMPRE, para o utilizador ver onde está)
        currentRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        
        // SE ESTIVER PAUSADO, NÃO GRAVA NADA DAQUI PARA BAIXO
        if isPaused {
            lastLocation = nil // Reseta o último ponto para não criar linhas retas gigantes ao retomar
            return
        }
        
        // 2. Calcula a distância e velocidade
        if let last = lastLocation {
            totalDistance += location.distance(from: last)
        }
        lastLocation = location
        currentSpeed = max(location.speed, 0)
        
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
