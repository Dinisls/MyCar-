import SwiftUI
import MapKit

struct HistoryView: View {
    var viewModel: AppViewModel
    
    // Estado para controlar a ordenação selecionada
    @State private var sortOption: SortOption = .dateNewest
    
    // Opções de ordenação disponíveis
    enum SortOption: String, CaseIterable, Identifiable {
        case dateNewest = "Newest First"
        case dateOldest = "Oldest First"
        case distanceHigh = "Longest Distance"
        case durationHigh = "Longest Duration"
        
        var id: String { self.rawValue }
    }
    
    // Lista calculada com base na ordenação
    var sortedTrips: [Trip] {
        switch sortOption {
        case .dateNewest:
            return viewModel.savedTrips.sorted { $0.startTime > $1.startTime }
        case .dateOldest:
            return viewModel.savedTrips.sorted { $0.startTime < $1.startTime }
        case .distanceHigh:
            return viewModel.savedTrips.sorted { $0.distance > $1.distance }
        case .durationHigh:
            return viewModel.savedTrips.sorted { $0.duration > $1.duration }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.savedTrips.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray.opacity(0.5))
                        Text("No trips recorded yet")
                            .font(.title2.bold())
                        Text("Start a new trip in the Tracking tab.")
                            .foregroundStyle(.gray)
                    }
                } else {
                    List {
                        // Usamos a lista ordenada aqui
                        ForEach(sortedTrips) { trip in
                            NavigationLink(destination: TripDetailView(trip: trip, viewModel: viewModel)) {
                                TripRow(trip: trip)
                            }
                        }
                        .onDelete(perform: deleteTrip)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Trip History")
            .toolbar {
                // Menu de Ordenação no topo
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort by", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Label(option.rawValue, systemImage: iconFor(option))
                                    .tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.headline)
                    }
                }
            }
        }
    }
    
    // Ícones para o menu
    func iconFor(_ option: SortOption) -> String {
        switch option {
        case .dateNewest, .dateOldest: return "calendar"
        case .distanceHigh: return "ruler"
        case .durationHigh: return "clock"
        }
    }
    
    // Função de apagar adaptada para listas ordenadas
    func deleteTrip(at offsets: IndexSet) {
        // 1. Identificar quais viagens queremos apagar na lista visual (ordenada)
        let tripsToDelete = offsets.map { sortedTrips[$0] }
        
        // 2. Encontrar essas viagens na lista original do ViewModel e apagar
        for trip in tripsToDelete {
            if let index = viewModel.savedTrips.firstIndex(where: { $0.id == trip.id }) {
                viewModel.deleteTrip(at: IndexSet(integer: index))
            }
        }
    }
}

// MARK: - SUBVIEW: Linha da Lista de Viagens
struct TripRow: View {
    let trip: Trip
    
    var body: some View {
        HStack {
            // Ícone do Mapa
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: "location.fill")
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // 1. DATA E HORA (Destaque conforme pedido)
                Text(trip.startTime.formatted(date: .numeric, time: .shortened)) // Ex: 17/01/2026, 13:12
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                // 2. Duração e Distância
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(formatDuration(trip.duration))
                    
                    Text("•")
                    
                    Image(systemName: "road.lanes")
                        .font(.caption2)
                    Text(String(format: "%.2f km", trip.distance / 1000))
                }
                .font(.caption)
                .foregroundStyle(.gray)
                
                // 3. Carro utilizado (se existir)
                if let car = trip.carName {
                    Text(car)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
    
    // Helper para formatar duração na linha
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0m"
    }
}
