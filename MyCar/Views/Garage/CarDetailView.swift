import SwiftUI

struct CarDetailView: View {
    var viewModel: AppViewModel
    var car: Car
    
    @State private var showingEditCar = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 1. IMAGEM DO CARRO (Grande)
                if let image = car.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                } else {
                    ZStack {
                        Rectangle().fill(Color.gray.opacity(0.2))
                        Image(systemName: "car.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                            .foregroundStyle(.gray)
                    }
                    .frame(height: 250)
                }
                
                // 2. TÍTULO E MATRÍCULA
                VStack(spacing: 5) {
                    Text("\(car.make) \(car.model)")
                        .font(.largeTitle.bold())
                    
                    Text(car.year)
                        .font(.title3)
                        .foregroundStyle(.gray)
                    
                    Text(car.licensePlate)
                        .font(.headline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .cornerRadius(8)
                        .padding(.top, 5)
                }
                .padding(.horizontal)
                
                // 3. GRELHA DE ESPECIFICAÇÕES
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    
                    // KMs
                    DetailCard(
                        title: "Odometer",
                        value: "\(Int(car.kilometers)) km",
                        icon: "road.lanes",
                        color: .blue
                    )
                    
                    // Combustível
                    DetailCard(
                        title: "Fuel Type",
                        value: car.fuelType,
                        icon: "fuelpump.fill",
                        color: .orange
                    )
                    
                    // Capacidade do Tanque (CORRIGIDO: tankCapacity)
                    DetailCard(
                        title: "Tank Capacity",
                        value: "\(Int(car.tankCapacity)) L",
                        icon: "drop.circle.fill",
                        color: .cyan
                    )
                    
                    // Potência (Novo)
                    DetailCard(
                        title: "Power",
                        value: "\(car.horsepower) hp",
                        icon: "bolt.fill",
                        color: .red
                    )
                    
                    // Cilindrada (Novo)
                    DetailCard(
                        title: "Engine",
                        value: "\(car.displacement) cc",
                        icon: "engine.combustion.fill", // SF Symbol requer iOS 17 (ou usa "gearshape.fill")
                        color: .gray
                    )
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditCar = true
                }
            }
        }
        // SHEET DE EDIÇÃO
        .sheet(isPresented: $showingEditCar) {
            EditCarView(viewModel: viewModel, car: car)
        }
    }
}

// Subview para os cartões de detalhe
struct DetailCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(alignment: .leading) {
                Text(value)
                    .font(.headline)
                    .foregroundStyle(.primary) // Adapta-se ao Dark Mode
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}
