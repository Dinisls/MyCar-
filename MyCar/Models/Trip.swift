import Foundation

struct Trip: Identifiable, Codable {
    var id = UUID()
    let points: [TripPoint]
    let startTime: Date
    let endTime: Date
    let distance: Double // Distância total em metros
    let carName: String?
    
    // --- PROPRIEDADES CALCULADAS ---
    
    // 1. Duração da viagem (Segundos)
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    // 2. Velocidade Média (km/h)
    var averageSpeedKmh: Double {
        guard duration > 0 else { return 0 }
        return (distance / duration) * 3.6
    }
    
    // 3. Velocidade Máxima (km/h)
    var maxSpeedKmh: Double {
        let maxSpeedMps = points.map { $0.speed }.max() ?? 0
        return maxSpeedMps > 0 ? (maxSpeedMps * 3.6) : 0
    }
    
    // 4. Tempo na "Red Zone" (> 150 km/h)  <-- AQUI ESTÁ O CÓDIGO QUE PEDISTE
    var redZoneDuration: TimeInterval {
        // Filtra os pontos onde a velocidade (convertida para km/h) é > 150
        let highSpeedPoints = points.filter { ($0.speed * 3.6) > 150 }
        // Como gravamos 1 ponto por segundo, o count é igual aos segundos
        return TimeInterval(highSpeedPoints.count)
    }
}
