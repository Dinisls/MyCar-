import SwiftUI

struct FuelCarListView: View {
    var viewModel: AppViewModel
    
    var body: some View {
        VStack {
            if viewModel.myCars.isEmpty {
                // Estado Vazio
                VStack(spacing: 20) {
                    Image(systemName: "fuelpump.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.gray)
                    Text("No Vehicles")
                        .font(.title2.bold())
                    Text("Add a car in the Garage tab to start tracking fuel.")
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                // Lista de Carros
                List {
                    ForEach(viewModel.myCars) { car in
                        NavigationLink(destination: FuelHistoryView(viewModel: viewModel, car: car)) {
                            FuelCarRow(car: car)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Select Vehicle")
        .background(Color.black)
    }
}

struct FuelCarRow: View {
    let car: Car
    
    var body: some View {
        HStack(spacing: 15) {
            if let image = car.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2))
                        .frame(width: 70, height: 70)
                    Image(systemName: "car.fill").foregroundStyle(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(car.make) \(car.model)")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                let totalSpent = car.fuelLogs.reduce(0) { $0 + $1.totalCost }
                Text("Total Spent: €\(String(format: "%.2f", totalSpent))")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.gray)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}
