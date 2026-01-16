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
    
    // MARK: - GESTÃO DE COMBUSTÍVEL
    
    func addFuelLog(_ log: FuelLog, to carID: UUID) {
        if let index = myCars.firstIndex(where: { $0.id == carID }) {
            var finalLog = log
            
            // Tenta obter o registo mais recente para cálculos
            if let previousLog = myCars[index].fuelLogs.first {
                if log.odometer > previousLog.odometer {
                    let dist = log.odometer - previousLog.odometer
                    finalLog.distanceTraveled = dist
                    
                    if dist > 0 && log.isFullTank {
                        let eff = (log.liters / dist) * 100
                        finalLog.efficiency = eff
                    } else {
                        finalLog.efficiency = nil
                    }
                }
            }
            
            // Insere o log
            myCars[index].fuelLogs.insert(finalLog, at: 0)
            
            // --- ATUALIZA KM DO CARRO (AQUI ESTÁ O QUE PEDISTE) ---
            if log.odometer > myCars[index].kilometers {
                myCars[index].kilometers = log.odometer
            }
            
            dataStore.saveCars(myCars)
        }
    }
    
    func deleteFuelLog(at offsets: IndexSet, from carID: UUID) {
        if let carIndex = myCars.firstIndex(where: { $0.id == carID }) {
            // Se apagarmos o registo mais recente, talvez devêssemos reverter os km do carro,
            // mas por segurança geralmente mantém-se o valor mais alto registado.
            myCars[carIndex].fuelLogs.remove(atOffsets: offsets)
            dataStore.saveCars(myCars)
        }
    }
    
    func updateFuelLog(_ updatedLog: FuelLog, for carID: UUID) {
        if let carIndex = myCars.firstIndex(where: { $0.id == carID }) {
            if let logIndex = myCars[carIndex].fuelLogs.firstIndex(where: { $0.id == updatedLog.id }) {
                
                var finalLog = updatedLog
                
                // Recalcular lógica com o registo anterior
                let prevIndex = logIndex + 1
                if prevIndex < myCars[carIndex].fuelLogs.count {
                    let previousLog = myCars[carIndex].fuelLogs[prevIndex]
                    
                    if finalLog.odometer > previousLog.odometer {
                        let dist = finalLog.odometer - previousLog.odometer
                        finalLog.distanceTraveled = dist
                        
                        if dist > 0 && finalLog.isFullTank {
                            let eff = (finalLog.liters / dist) * 100
                            finalLog.efficiency = eff
                        } else {
                            finalLog.efficiency = nil
                        }
                    }
                }
                
                // Atualiza o log na lista
                myCars[carIndex].fuelLogs[logIndex] = finalLog
                
                // --- ATUALIZA KM DO CARRO (EDITAR) ---
                // Se estamos a editar o registo mais recente (índice 0) E os kms aumentaram
                // ou mudaram para um valor superior ao que o carro tem:
                if logIndex == 0 {
                    // Simplesmente definimos os kms do carro para os kms deste log mais recente
                    myCars[carIndex].kilometers = finalLog.odometer
                }
                // Se editarmos um log antigo (não o primeiro), não atualizamos os kms atuais do carro
                // porque o carro já deve ter kms superiores de logs mais recentes.
                
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
