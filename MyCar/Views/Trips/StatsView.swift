import SwiftUI
import Charts

struct StatsView: View {
    var viewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                Text("Statistics")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)
                    .padding(.top)
                
                // --- 1. GRELHA DE 4 CARTÕES ---
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    
                    // Distância Total
                    StatsBigCard(
                        value: String(format: "%.1f km", viewModel.totalDistanceAllTime / 1000),
                        label: "Total Distance",
                        icon: "road.lanes",
                        iconColor: .blue
                    )
                    
                    // Tempo Total
                    StatsBigCard(
                        value: formatSimpleDuration(viewModel.totalDurationAllTime),
                        label: "Total Time",
                        icon: "clock.fill",
                        iconColor: .green
                    )
                    
                    // Top Speed
                    StatsBigCard(
                        value: String(format: "%.0f km/h", viewModel.topSpeedAllTime),
                        label: "Top Speed",
                        icon: "speedometer",
                        iconColor: .red
                    )
                    
                    // Número de Viagens
                    StatsBigCard(
                        value: "\(viewModel.savedTrips.count)",
                        label: "Trips",
                        icon: "flag.checkered",
                        iconColor: .yellow
                    )
                }
                .padding(.horizontal)
                
                // --- 2. GRÁFICO DE DISTRIBUIÇÃO ---
                VStack(alignment: .leading, spacing: 10) {
                    Text("Speed Distribution")
                        .font(.headline)
                    
                    if viewModel.savedTrips.isEmpty {
                        Text("No data available yet.")
                            .font(.caption).foregroundStyle(.gray).padding()
                    } else {
                        Chart(viewModel.speedDistribution) { item in
                            BarMark(
                                x: .value("Range", item.range),
                                y: .value("Minutes", item.minutes)
                            )
                            .foregroundStyle(item.color) // Usa a cor definida no ViewModel
                        }
                        .frame(height: 250)
                        
                        // Legenda Manual (como na foto)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                LegendItem(color: .green, text: "0-60")
                                LegendItem(color: .blue, text: "61-90")
                                LegendItem(color: .yellow, text: "91-120")
                                LegendItem(color: .orange, text: "121-150")
                                LegendItem(color: .red, text: "151+")
                            }
                        }
                        .padding(.top, 5)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .background(Color.black)
        // Removemos o navigationTitle padrão para usarmos o Text("Statistics") grande personalizado
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func formatSimpleDuration(_ totalSeconds: TimeInterval) -> String {
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

// Cartão Grande para a Stats View
struct StatsBigCard: View {
    let value: String
    let label: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
            
            VStack(spacing: 5) {
                Text(value)
                    .font(.title2.bold()) // Texto ligeiramente maior
                    .foregroundStyle(.white)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110) // Altura fixa para ficarem quadrados
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }
}

// Item da Legenda
struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(.caption).foregroundStyle(.gray)
        }
    }
}
