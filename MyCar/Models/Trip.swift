import Foundation
import CoreLocation

struct Trip: Identifiable, Codable {
    var id = UUID()
    let points: [RoutePoint]
    let startTime: Date
    let endTime: Date
    let distance: Double // em metros
    var carName: String?
    
    // Duração calculada
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    // --- NOVAS PROPRIEDADES CALCULADAS (Correção do erro) ---
    
    // Velocidade Média em km/h
    var avgSpeedKmh: Double {
        guard duration > 0 else { return 0 }
        let hours = duration / 3600
        let km = distance / 1000
        return km / hours
    }
    
    // Velocidade Máxima em km/h
    var maxSpeedKmh: Double {
        // Os pontos guardam velocidade em m/s, convertemos para km/h (* 3.6)
        let maxMps = points.map { $0.speed }.max() ?? 0
        return maxMps * 3.6
    }
}

// Estrutura auxiliar para guardar pontos da rota (GeoJSON simplificado)
struct RoutePoint: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let speed: Double // m/s
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
