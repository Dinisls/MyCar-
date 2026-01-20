import SwiftUI
import Charts

struct StatsView: View {
    var viewModel: AppViewModel
    
    // Filtro de tempo selecionado
    @State private var selectedTimeRange = "All Time"
    let timeRanges = ["Week", "Month", "Year", "All Time"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Seletor de Tempo
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(timeRanges, id: \.self) { range in
                            Text(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // 1. ESTATÍSTICAS GERAIS
                    VStack(spacing: 15) {
                        Text("Overview")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            StatBox(
                                title: "Total Distance",
                                value: String(format: "%.0f km", viewModel.totalDistanceAllTime / 1000),
                                icon: "road.lanes",
                                color: .blue
                            )
                            
                            StatBox(
                                title: "Total Time",
                                value: formatDuration(viewModel.totalDurationAllTime),
                                icon: "clock.fill",
                                color: .orange
                            )
                            
                            StatBox(
                                title: "Top Speed",
                                value: String(format: "%.0f km/h", viewModel.topSpeedAllTime),
                                icon: "trophy.fill",
                                color: .yellow
                            )
                            
                            StatBox(
                                title: "Trips",
                                value: "\(viewModel.savedTrips.count)",
                                icon: "flag.checkered",
                                color: .green
                            )
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 2. GRÁFICO DE DISTRIBUIÇÃO DE VELOCIDADE
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Speed Distribution (Time spent)")
                            .font(.headline)
                        
                        if viewModel.savedTrips.isEmpty {
                            Text("No data available yet.")
                                .foregroundStyle(.gray)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                        } else {
                            Chart(viewModel.speedDistribution) { item in
                                SectorMark(
                                    angle: .value("Minutes", item.minutes),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .foregroundStyle(item.color)
                                .cornerRadius(5)
                            }
                            .frame(height: 250)
                            
                            // Legenda
                            VStack(alignment: .leading, spacing: 8) {
                                // CORREÇÃO: Usamos o novo nome StatsLegendItem
                                StatsLegendItem(color: .green, text: "0 - 60 km/h (City)")
                                StatsLegendItem(color: .blue, text: "61 - 90 km/h (Road)")
                                StatsLegendItem(color: .yellow, text: "91 - 120 km/h (Highway)")
                                StatsLegendItem(color: .orange, text: "121 - 150 km/h (Fast)")
                                StatsLegendItem(color: .red, text: "> 150 km/h (Extreme)")
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Statistics")
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0h"
    }
}

// MARK: - SUBVIEWS

struct StatBox: View {
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
                    .font(.title3.bold())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// CORREÇÃO: Nome alterado para evitar conflito com TripDetailView
struct StatsLegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
