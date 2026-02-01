import Foundation
import SwiftUI
import CoreLocation

// Estrutura para os Gráficos
struct SpeedDistributionData: Identifiable {
    var id = UUID()
    let range: String
    let color: Color
    var minutes: Double
}

struct BackupData: Codable {
    let version: String
    let timestamp: Date
    let cars: [Car]
    let trips: [Trip]
}

@Observable
class AppViewModel {
    var locationManager = LocationManager()
    private var dataStore = DataStore()
    
    var savedTrips: [Trip] = []
    var myCars: [Car] = []
    
    // Estado do Tracking
    var isTracking = false
    var isPaused = false
    
    var trackStartTime: Date?
    var currentDuration: TimeInterval = 0
    private var timer: Timer?
    var currentTripCar: Car?
    
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
            var newLog = log
            let carCapacity = myCars[index].tankCapacity
            
            newLog.efficiency = nil
            
            if let previousLog = myCars[index].fuelLogs.first {
                let dist = newLog.odometer - previousLog.odometer
                newLog.distanceTraveled = dist
                
                var consumedLiters: Double = 0.0
                let levelAfterPrev = previousLog.fuelLevelAfter ?? (previousLog.isFullTank ? 1.0 : 0)
                let levelBeforeCurr = newLog.fuelLevelBefore
                
                if carCapacity > 0 && levelAfterPrev > 0 {
                    let percentageUsed = max(0, levelAfterPrev - levelBeforeCurr)
                    consumedLiters = percentageUsed * carCapacity
                    
                    if consumedLiters == 0 && newLog.isFullTank {
                        consumedLiters = newLog.liters
                    }
                } else {
                    if newLog.isFullTank {
                        consumedLiters = newLog.liters
                    }
                }
                
                if dist > 0 && consumedLiters > 0 {
                    let efficiency = (consumedLiters / dist) * 100
                    myCars[index].fuelLogs[0].efficiency = efficiency
                }
            }
            
            myCars[index].fuelLogs.insert(newLog, at: 0)
            
            if newLog.odometer > myCars[index].kilometers {
                myCars[index].kilometers = newLog.odometer
            }
            
            dataStore.saveCars(myCars)
        }
    }
    
    func deleteFuelLog(at offsets: IndexSet, from carID: UUID) {
        if let carIndex = myCars.firstIndex(where: { $0.id == carID }) {
            myCars[carIndex].fuelLogs.remove(atOffsets: offsets)
            
            if let newLatestLog = myCars[carIndex].fuelLogs.first {
                myCars[carIndex].kilometers = newLatestLog.odometer
                var updatedLog = newLatestLog
                updatedLog.efficiency = nil
                myCars[carIndex].fuelLogs[0] = updatedLog
            }
            dataStore.saveCars(myCars)
        }
    }
    
    func updateFuelLog(_ updatedLog: FuelLog, for carID: UUID) {
        if let carIndex = myCars.firstIndex(where: { $0.id == carID }) {
            if let logIndex = myCars[carIndex].fuelLogs.firstIndex(where: { $0.id == updatedLog.id }) {
                myCars[carIndex].fuelLogs[logIndex] = updatedLog
                if logIndex == 0 { myCars[carIndex].kilometers = updatedLog.odometer }
                dataStore.saveCars(myCars)
            }
        }
    }

    // MARK: - BACKUP
    func createUnifiedBackup() -> URL? {
        let backup = BackupData(version: "1.0", timestamp: Date(), cars: myCars, trips: savedTrips)
        do {
            let data = try JSONEncoder().encode(backup)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let fileName = "MyCar_Backup_\(dateFormatter.string(from: Date())).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("❌ Erro backup: \(error)")
            return nil
        }
    }
    
    func restoreUnifiedBackup(from url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let backup = try JSONDecoder().decode(BackupData.self, from: data)
            self.myCars = backup.cars
            self.savedTrips = backup.trips
            dataStore.saveCars(self.myCars)
            dataStore.saveTrips(self.savedTrips)
            return true
        } catch {
            print("❌ Erro restore: \(error)")
            return false
        }
    }
    
    // MARK: - CONTROLO DA VIAGEM
    func startTrip(with car: Car? = nil) {
        locationManager.startRecording()
        isTracking = true
        isPaused = false
        trackStartTime = Date()
        currentDuration = 0
        currentTripCar = car
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.isPaused {
                self.currentDuration += 1
            }
        }
    }
    
    func togglePause() {
        isPaused.toggle()
        locationManager.isPaused = isPaused
    }
    
    func stopTrip() {
        locationManager.stopRecording()
        isTracking = false
        isPaused = false
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
            if !newTrip.points.isEmpty {
                savedTrips.insert(newTrip, at: 0)
                dataStore.saveTrips(savedTrips)
            }
        }
        currentTripCar = nil
    }
    
    func deleteTrip(at offsets: IndexSet) {
        savedTrips.remove(atOffsets: offsets)
        dataStore.saveTrips(savedTrips)
    }
    
    func resetAllData() {
        if isTracking { stopTrip() }
        savedTrips = []
        myCars = []
        dataStore.saveTrips([])
        dataStore.saveCars([])
    }
    
    // MARK: - ESTATÍSTICAS COM FILTRO
    
    func filteredTrips(for range: String) -> [Trip] {
        let calendar = Calendar.current
        let now = Date()
        
        switch range {
        case "Week":
            // Últimos 7 dias
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return savedTrips.filter { $0.startTime >= weekAgo }
            
        case "Month":
            // Últimos 30 dias
            let monthAgo = calendar.date(byAdding: .day, value: -30, to: now)!
            return savedTrips.filter { $0.startTime >= monthAgo }
            
        case "Year":
            // Últimos 365 dias
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
            return savedTrips.filter { $0.startTime >= yearAgo }
            
        default: // "All Time"
            return savedTrips
        }
    }
    
    // Retorna a distância total filtrada
    func getFilteredDistance(range: String) -> Double {
        return filteredTrips(for: range).reduce(0) { $0 + $1.distance }
    }
    
    // Retorna a duração total filtrada
    func getFilteredDuration(range: String) -> TimeInterval {
        return filteredTrips(for: range).reduce(0) { $0 + $1.duration }
    }
    
    // Retorna velocidade máxima filtrada
    func getFilteredTopSpeed(range: String) -> Double {
        return filteredTrips(for: range).map { $0.maxSpeedKmh }.max() ?? 0
    }
    
    // Retorna contagem filtrada
    func getFilteredCount(range: String) -> Int {
        return filteredTrips(for: range).count
    }
    
    // Retorna distribuição de velocidade filtrada
    func getSpeedDistribution(for range: String) -> [SpeedDistributionData] {
        let trips = filteredTrips(for: range)
        var data = [
            SpeedDistributionData(range: "0-60", color: .green, minutes: 0),
            SpeedDistributionData(range: "61-90", color: .blue, minutes: 0),
            SpeedDistributionData(range: "91-120", color: .yellow, minutes: 0),
            SpeedDistributionData(range: "121-150", color: .orange, minutes: 0),
            SpeedDistributionData(range: "151+", color: .red, minutes: 0)
        ]
        
        for trip in trips {
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
    
    // MARK: - HELPER VISUAIS E DE DATAS
    
    func getColorForSpeed(kmh: Double) -> Color {
        switch kmh {
        case 0...60: return .green
        case 60.001...90: return .blue
        case 90.001...120: return .yellow
        case 120.001...150: return .orange
        default: return .red
        }
    }
    
    /// Retorna a string do intervalo (Ex: "02 jan. 2026 – 01 fev. 2026")
    func getDateRangeString(for range: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current // Usa o idioma do telemóvel
        
        let now = Date()
        let calendar = Calendar.current
        var startDate: Date
        
        switch range {
        case "Week":
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case "Month":
            startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case "Year":
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        default: // "All Time"
            // Se "Tudo", usa a data da viagem mais antiga (a última do array, pois inserimos no início)
            if let oldest = savedTrips.last {
                startDate = oldest.startTime
            } else {
                // Se não houver viagens, mostramos algo genérico ou vazio
                return "No data"
            }
        }
        
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: now))"
    }
    
    // Variáveis legacy
    var totalDistanceAllTime: Double { savedTrips.reduce(0) { $0 + $1.distance } }
    var totalDurationAllTime: TimeInterval { savedTrips.reduce(0) { $0 + $1.duration } }
    var topSpeedAllTime: Double { savedTrips.map { $0.maxSpeedKmh }.max() ?? 0 }
    
    var speedDistribution: [SpeedDistributionData] {
        return getSpeedDistribution(for: "All Time")
    }
}

// Extension Helper
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
