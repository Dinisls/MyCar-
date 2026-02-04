import Foundation

struct ServiceLog: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let type: String      // Ex: Óleo, Pneus, Inspeção
    let cost: Double
    let odometer: Double
    let notes: String     // Descrição extra
}