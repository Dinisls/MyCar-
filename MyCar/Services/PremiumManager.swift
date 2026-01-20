import SwiftUI
import StoreKit

class PremiumManager: ObservableObject {
    static let shared = PremiumManager()
    
    // --- ESTADO DA SUBSCRIÇÃO ---
    @AppStorage("isPremium") var isPremium: Bool = false
    @AppStorage("premiumExpiryDate") var premiumExpiryDate: Double = 0 // Timestamp
    
    // --- CONTADORES GRATUITOS ---
    // Guardamos o total de viagens iniciadas e logs adicionados
    @AppStorage("totalTripsStarted") var totalTripsStarted: Int = 0
    @AppStorage("totalFuelLogsAdded") var totalFuelLogsAdded: Int = 0
    
    // Limites
    let freeTripLimit = 2 // "Gratuita até à terceira viagem" significa que a 3ª já bloqueia? Ou faz 3 e bloqueia a 4ª?
                          // O teu texto diz: "Ao iniciar a terceira viagem, será apresentada uma tela". Portanto, limite = 2.
    let freeFuelLimit = 2
    
    // --- VERIFICAÇÕES ---
    
    func canStartTrip() -> Bool {
        if isPremium { return true }
        return totalTripsStarted < freeTripLimit
    }
    
    func canAddFuelLog() -> Bool {
        if isPremium { return true }
        return totalFuelLogsAdded < freeFuelLimit
    }
    
    // --- AÇÕES ---
    
    func incrementTripCount() {
        totalTripsStarted += 1
    }
    
    func incrementFuelLogCount() {
        totalFuelLogsAdded += 1
    }
    
    // --- SIMULAÇÃO DE COMPRA E ADS (Para testares agora) ---
    
    func buyMonthly() {
        // AQUI ENTRARIA O CÓDIGO STOREKIT
        print("A comprar plano mensal...")
        activatePremium(months: 1)
    }
    
    func buyYearly() {
        // AQUI ENTRARIA O CÓDIGO STOREKIT
        print("A comprar plano anual...")
        activatePremium(months: 12)
    }
    
    func watchAd(completion: @escaping (Bool) -> Void) {
        // AQUI ENTRARIA O CÓDIGO ADMOB (Google Mobile Ads)
        // Simulamos um delay de 2 segundos como se fosse o anúncio
        print("A mostrar anúncio...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("Anúncio terminado com sucesso!")
            completion(true) // Sucesso
        }
    }
    
    private func activatePremium(months: Int) {
        isPremium = true
        // Calcula nova data: Agora + X meses
        let newDate = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
        premiumExpiryDate = newDate.timeIntervalSince1970
    }
}