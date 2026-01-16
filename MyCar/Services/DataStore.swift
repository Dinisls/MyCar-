import Foundation

class DataStore {
    private let tripsFileName = "trips_v1.json"
    private let carsFileName = "my_cars_v1.json"
    
    private func getURL(for file: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(file)
    }
    
    // --- VIAGENS ---
    func saveTrips(_ trips: [Trip]) {
        do {
            let data = try JSONEncoder().encode(trips)
            try data.write(to: getURL(for: tripsFileName))
        } catch {
            print("❌ Erro ao guardar viagens: \(error)")
        }
    }
    
    func loadTrips() -> [Trip] {
        guard let data = try? Data(contentsOf: getURL(for: tripsFileName)) else { return [] }
        return (try? JSONDecoder().decode([Trip].self, from: data)) ?? []
    }
    
    // --- CARROS (NOVO) ---
    func saveCars(_ cars: [Car]) {
        do {
            let data = try JSONEncoder().encode(cars)
            try data.write(to: getURL(for: carsFileName))
        } catch {
            print("❌ Erro ao guardar carros: \(error)")
        }
    }
    
    func loadCars() -> [Car] {
        guard let data = try? Data(contentsOf: getURL(for: carsFileName)) else { return [] }
        return (try? JSONDecoder().decode([Car].self, from: data)) ?? []
    }
}
