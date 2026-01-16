import Foundation
import SwiftUI

struct Car: Identifiable, Codable {
    var id = UUID()
    var make: String
    var model: String
    var year: String
    var licensePlate: String
    var kilometers: Double
    var fuelType: String
    
    // CAMPOS TÉCNICOS ADICIONAIS
    var tankCapacity: Double // Capacidade do Tanque (Litros)
    var horsepower: Int      // Cavalos (cv/hp)
    var displacement: Int    // Cilindrada (cc)
    
    var imageData: Data?
    
    // Histórico
    var fuelLogs: [FuelLog] = []
    
    // Helper de Imagem
    var image: Image? {
        if let data = imageData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
}
