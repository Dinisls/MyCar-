import Foundation
import SwiftUI
import CoreLocation

struct SpeedDistributionData: Identifiable {
    var id = UUID()
    let range: String
    let color: Color
    var minutes: Double
}

@Observable
class AppViewModel {
    var locationManager = LocationManager()
    private var dataStore = DataStore()
    
    var savedTrips: [Trip] = []
    var isTracking = false
    var trackStartTime: Date?
    var currentDuration: TimeInterval = 0
    private var timer: Timer?
    var currentTripCar: Car?
    
    var myCars: [Car] = []
    
    init() {
        savedTrips = dataStore.loadTrips()
        myCars = dataStore.loadCars()
    }
    
    // MARK: - GESTÃO DA GARAGEM
    func addCar(_ car: Car) {
        myCars.append(car)
        dataStore.saveCars(myCars)
    }
    
    func deleteCar(at offsets: IndexSet) {
        myCars.remove(atOffsets: offsets)
        dataStore.saveCars(myCars)
    }
    
    func updateCar(_ updatedCar: Car) {
        if let index = myCars.firstIndex(where: { $0.id == updatedCar.id }) {
            myCars[index] = updatedCar
            dataStore.saveCars(myCars)
        }
    }
    
    // MARK: - GESTÃO DE COMBUSTÍVEL (LÓGICA CORRIGIDA: NÍVEL DO TANQUE)
    
    func addFuelLog(_ log: FuelLog, to carID: UUID) {
        if let index = myCars.firstIndex(where: { $0.id == carID }) {
            var newLog = log
            let carCapacity = myCars[index].tankCapacity
            
            // O novo log começa sem eficiência (será calculada quando houver um próximo)
            newLog.efficiency = nil
            
            // Verifica se existe log anterior
            if let previousLog = myCars[index].fuelLogs.first {
                
                // 1. Calcula distância percorrida
                let dist = newLog.odometer - previousLog.odometer
                newLog.distanceTraveled = dist
                
                // 2. CÁLCULO DO CONSUMO (A LÓGICA QUE PEDISTE)
                // Vamos calcular quantos litros foram realmente "queimados" com base na diferença de nível do tanque.
                
                var consumedLiters: Double = 0.0
                
                // Recuperamos o nível com que o carro ficou DEPOIS do abastecimento anterior
                // Se não tiver registo, assumimos 1.0 (Cheio) se foi marcado como Full, ou 0 se não sabemos.
                let levelAfterPrev = previousLog.fuelLevelAfter ?? (previousLog.isFullTank ? 1.0 : 0)
                
                // O nível com que chegaste AGORA à bomba (ex: 0.50 ou 50%)
                let levelBeforeCurr = newLog.fuelLevelBefore
                
                // Se o carro tiver capacidade definida e os níveis forem válidos
                if carCapacity > 0 && levelAfterPrev > 0 {
                    // Diferença: Saiu com 100%, Chegou com 50% -> Gastou 50%
                    let percentageUsed = max(0, levelAfterPrev - levelBeforeCurr)
                    consumedLiters = percentageUsed * carCapacity
                    
                    // SEGURANÇA:
                    // Se o cálculo pelos níveis der zero (ex: o utilizador esqueceu-se dos sliders),
                    // e o utilizador atestou agora (Full Tank), usamos os litros da bomba como fallback.
                    if consumedLiters == 0 && newLog.isFullTank {
                        consumedLiters = newLog.liters
                    }
                } else {
                    // Se não temos capacidade do tanque configurada, usamos a lógica antiga (Litros da Bomba)
                    // Mas apenas se for Tanque Cheio, senão não conseguimos adivinhar.
                    if newLog.isFullTank {
                        consumedLiters = newLog.liters
                    }
                }
                
                // 3. Atualiza a eficiência do log ANTERIOR
                if dist > 0 && consumedLiters > 0 {
                    let efficiency = (consumedLiters / dist) * 100
                    myCars[index].fuelLogs[0].efficiency = efficiency
                }
            }
            
            // Insere o novo log
            myCars[index].fuelLogs.insert(newLog, at: 0)
            
            // Atualiza KMs
            if newLog.odometer > myCars[index].kilometers {
                myCars[index].kilometers = newLog.odometer
            }
            
            dataStore.saveCars(myCars)
        }
    }
    
    func deleteFuelLog(at offsets: IndexSet, from carID: UUID) {
        if let carIndex = myCars.firstIndex(where: { $0.id == carID }) {
            myCars[carIndex].fuelLogs.remove(atOffsets: offsets)
            
            // Ao apagar, tentamos recuperar a consistência do último log
            if let newLatestLog = myCars[carIndex].fuelLogs.first {
                myCars[carIndex].kilometers = newLatestLog.odometer
                
                var updatedLog = newLatestLog
                updatedLog.efficiency = nil // Perdeu a referência de consumo futuro
                myCars[carIndex].fuelLogs[0] = updatedLog
            }
            dataStore.saveCars(myCars)
        }
    }
    
    func updateFuelLog(_ updatedLog: FuelLog, for carID: UUID) {
        if let carIndex = myCars.firstIndex(where: { $0.id == carID }) {
            if let logIndex = myCars[carIndex].fuelLogs.firstIndex(where: { $0.id == updatedLog.id }) {
                
                var currentLog = updatedLog
                let carCapacity = myCars[carIndex].tankCapacity
                
                let nextLogIndex = logIndex - 1 // Futuro
                let prevLogIndex = logIndex + 1 // Passado
                
                // 1. ATUALIZAR ESTE LOG (Com base no Passado)
                if prevLogIndex < myCars[carIndex].fuelLogs.count {
                    let prevLog = myCars[carIndex].fuelLogs[prevLogIndex]
                    let dist = currentLog.odometer - prevLog.odometer
                    currentLog.distanceTraveled = dist
                    
                    // RECALCULAR EFICIÊNCIA DO ANTERIOR
                    // Baseado nos níveis: (NivelFinalAnterior - NivelInicialDeste) * Capacidade
                    let levelAfterPrev = prevLog.fuelLevelAfter ?? (prevLog.isFullTank ? 1.0 : 0)
                    let levelBeforeCurr = currentLog.fuelLevelBefore
                    
                    var consumedLiters = 0.0
                    
                    if carCapacity > 0 && levelAfterPrev > 0 {
                        let pctUsed = max(0, levelAfterPrev - levelBeforeCurr)
                        consumedLiters = pctUsed * carCapacity
                    }
                    // Fallback se os sliders falharem mas for tanque cheio
                    if consumedLiters == 0 && currentLog.isFullTank {
                        consumedLiters = currentLog.liters
                    }
                    
                    if dist > 0 && consumedLiters > 0 {
                        let prevEff = (consumedLiters / dist) * 100
                        myCars[carIndex].fuelLogs[prevLogIndex].efficiency = prevEff
                    }
                }
                
                // 2. ATUALIZAR EFICIÊNCIA DESTE LOG (Com base no Futuro)
                if nextLogIndex >= 0 {
                    var nextLog = myCars[carIndex].fuelLogs[nextLogIndex]
                    
                    let distNext = nextLog.odometer - currentLog.odometer
                    nextLog.distanceTraveled = distNext
                    
                    // Consumo DESTE log = (NivelFinalDeste - NivelInicialProximo) * Capacidade
                    let levelAfterCurr = currentLog.fuelLevelAfter ?? (currentLog.isFullTank ? 1.0 : 0)
                    let levelBeforeNext = nextLog.fuelLevelBefore
                    
                    var consumedNext = 0.0
                    
                    if carCapacity > 0 && levelAfterCurr > 0 {
                        let pctUsed = max(0, levelAfterCurr - levelBeforeNext)
                        consumedNext = pctUsed * carCapacity
                    }
                    
                    if consumedNext == 0 && nextLog.isFullTank {
                        consumedNext = nextLog.liters
                    }
                    
                    if distNext > 0 && consumedNext > 0 {
                        currentLog.efficiency = (consumedNext / distNext) * 100
                    } else {
                        currentLog.efficiency = nil
                    }
                    
                    myCars[carIndex].fuelLogs[nextLogIndex] = nextLog
                } else {
                    currentLog.efficiency = nil
                }
                
                myCars[carIndex].fuelLogs[logIndex] = currentLog
                
                if logIndex == 0 {
                    myCars[carIndex].kilometers = currentLog.odometer
                }
                
                dataStore.saveCars(myCars)
            }
        }
    }
    
    // MARK: - CONTROLO DA VIAGEM
    func startTrip(with car: Car? = nil) {
        locationManager.startRecording()
        isTracking = true
        trackStartTime = Date()
        currentDuration = 0
        currentTripCar = car
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.currentDuration += 1
        }
    }
    
    func stopTrip() {
        locationManager.stopRecording()
        isTracking = false
        timer?.invalidate()
        timer = nil
        if let start = trackStartTime {
            let carName = currentTripCar != nil ? "\(currentTripCar!.make) \(currentTripCar!.model)" : nil
            let newTrip = Trip(
                points: locationManager.routePoints,
                startTime: start,
                endTime: Date(),
                distance: locationManager.totalDistance,
                carName: carName
            )
            savedTrips.insert(newTrip, at: 0)
            dataStore.saveTrips(savedTrips)
        }
        currentTripCar = nil
    }
    
    func deleteTrip(at offsets: IndexSet) {
        savedTrips.remove(atOffsets: offsets)
        dataStore.saveTrips(savedTrips)
    }
    
    func resetAllData() {
        if isTracking {
            locationManager.stopRecording()
            isTracking = false
            timer?.invalidate()
            timer = nil
        }
        savedTrips = []
        myCars = []
        dataStore.saveTrips([])
        dataStore.saveCars([])
    }
    
    // MARK: - ESTATÍSTICAS
    var totalDistanceAllTime: Double { savedTrips.reduce(0) { $0 + $1.distance } }
    var totalDurationAllTime: TimeInterval { savedTrips.reduce(0) { $0 + $1.duration } }
    var topSpeedAllTime: Double { savedTrips.map { $0.maxSpeedKmh }.max() ?? 0 }
    
    var speedDistribution: [SpeedDistributionData] {
        var data = [
            SpeedDistributionData(range: "0-60", color: .green, minutes: 0),
            SpeedDistributionData(range: "61-90", color: .blue, minutes: 0),
            SpeedDistributionData(range: "91-120", color: .yellow, minutes: 0),
            SpeedDistributionData(range: "121-150", color: .orange, minutes: 0),
            SpeedDistributionData(range: "151+", color: .red, minutes: 0)
        ]
        for trip in savedTrips {
            guard trip.points.count > 1 else { continue }
            for i in 0..<(trip.points.count - 1) {
                let p1 = trip.points[i]
                let p2 = trip.points[i+1]
                let durationInMinutes = p2.timestamp.timeIntervalSince(p1.timestamp) / 60.0
                let speedKmh = p1.speed * 3.6
                if speedKmh <= 60 { data[0].minutes += durationInMinutes }
                else if speedKmh <= 90 { data[1].minutes += durationInMinutes }
                else if speedKmh <= 120 { data[2].minutes += durationInMinutes }
                else if speedKmh <= 150 { data[3].minutes += durationInMinutes }
                else { data[4].minutes += durationInMinutes }
            }
        }
        return data
    }
    
    func getColorForSpeed(kmh: Double) -> Color {
        switch kmh {
        case 0...60: return .green
        case 60.001...90: return .blue
        case 90.001...120: return .yellow
        case 120.001...150: return .orange
        default: return .red
        }
    }
}

extension Calendar {
    func isDate(_ date: Date, equalTo otherDate: Date, toGranularity component: Calendar.Component) -> Bool {
        return compare(date, to: otherDate, toGranularity: component) == .orderedSame
    }
    func isDateInPrevYear(_ date: Date) -> Bool {
        let currentYear = component(.year, from: Date())
        let targetYear = component(.year, from: date)
        return targetYear == (currentYear - 1)
    }
    func isDateInPrevMonth(_ date: Date) -> Bool {
        guard let prevMonthDate = self.date(byAdding: .month, value: -1, to: Date()) else { return false }
        return isDate(date, equalTo: prevMonthDate, toGranularity: .month) &&
               isDate(date, equalTo: prevMonthDate, toGranularity: .year)
    }
}
