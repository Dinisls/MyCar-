import SwiftUI

struct HistoryView: View {
    var viewModel: AppViewModel
    
    var body: some View {
        VStack {
            if viewModel.savedTrips.isEmpty {
                // Estado Vazio
                VStack(spacing: 20) {
                    Image(systemName: "map")
                        .font(.system(size: 60))
                        .foregroundStyle(.gray)
                    Text("No Trips Yet")
                        .font(.title2.bold())
                    Text("Record your first trip in the Tracking tab.")
                        .foregroundStyle(.gray)
                }
            } else {
                // Lista de Viagens
                List {
                    ForEach(viewModel.savedTrips) { trip in
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            TripRow(trip: trip)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deleteTrip)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black)
    }
    
    func deleteTrip(at offsets: IndexSet) {
        viewModel.deleteTrip(at: offsets)
    }
}

// Subview da Linha da Lista
struct TripRow: View {
    let trip: Trip
    
    var body: some View {
        HStack {
            // Data (Dia e Mês)
            VStack {
                Text(trip.startTime.formatted(.dateTime.day()))
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                // CORREÇÃO AQUI:
                Text(trip.startTime.formatted(.dateTime.month()))
                    .font(.caption)
                    .textCase(.uppercase) // Transforma em maiúsculas (JAN, FEV)
                    .foregroundStyle(.gray)
            }
            .frame(width: 60)
            .padding(.trailing, 5)
            
            // Info da Viagem
            VStack(alignment: .leading, spacing: 4) {
                if let carName = trip.carName {
                    Text(carName)
                        .font(.headline)
                        .foregroundStyle(.white)
                } else {
                    Text("Trip")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                HStack {
                    Text(formatTime(trip.duration))
                    Text("•")
                    Text(String(format: "%.1f km", trip.distance / 1000))
                }
                .font(.caption)
                .foregroundStyle(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: time) ?? ""
    }
}
