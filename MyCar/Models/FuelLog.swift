import Foundation

struct FuelLog: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let odometer: Double
    let liters: Double
    let pricePerLiter: Double
    let totalCost: Double
    let fuelType: String
    
    // Níveis do Tanque
    let fuelLevelBefore: Double // 0.0 a 1.0
    var fuelLevelAfter: Double? // Resultado do cálculo
    
    // NOVO: Depósito Cheio (Isto corrige o teu erro)
    var isFullTank: Bool
    
    // Campos Opcionais de Cálculo
    var distanceTraveled: Double?
    var efficiency: Double?
    
    var stationName: String? = "Station"
}
