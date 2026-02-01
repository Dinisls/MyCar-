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
                    
                    // Texto com as datas (Ex: 1 Jan - 1 Fev)
                    Text(viewModel.getDateRangeString(for: selectedTimeRange))
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // 1. ESTATÍSTICAS GERAIS (Grelha)
                    VStack(spacing: 15) {
                        Text("Overview")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            
                            // Distância Filtrada
                            StatBox(
                                title: "Distance",
                                value: String(format: "%.0f km", viewModel.getFilteredDistance(range: selectedTimeRange) / 1000),
                                icon: "road.lanes",
                                color: .blue
                            )
                            
                            // Tempo Filtrado
                            StatBox(
                                title: "Total Time",
                                value: formatDuration(viewModel.getFilteredDuration(range: selectedTimeRange)),
                                icon: "clock.fill",
                                color: .orange
                            )
                            
                            // Velocidade Máxima Filtrada
                            StatBox(
                                title: "Top Speed",
                                value: String(format: "%.0f km/h", viewModel.getFilteredTopSpeed(range: selectedTimeRange)),
                                icon: "trophy.fill",
                                color: .yellow
                            )
                            
                            // Contagem Filtrada
                            StatBox(
                                title: "Trips",
                                value: "\(viewModel.getFilteredCount(range: selectedTimeRange))",
                                icon: "flag.checkered",
                                color: .green
                            )
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 2. GRÁFICO DE DISTRIBUIÇÃO (Donut)
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Speed Distribution")
                            .font(.headline)
                        
                        let distData = viewModel.getSpeedDistribution(for: selectedTimeRange)
                        let totalMinutes = distData.reduce(0) { $0 + $1.minutes }
                        
                        if totalMinutes == 0 {
                            VStack {
                                Image(systemName: "chart.pie.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.gray)
                                Text("No speed data")
                                    .foregroundStyle(.gray)
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                        } else {
                            HStack {
                                Chart(distData) { item in
                                    SectorMark(
                                        angle: .value("Minutes", item.minutes),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 2
                                    )
                                    .foregroundStyle(item.color)
                                    .cornerRadius(5)
                                }
                                .frame(height: 200)
                                
                                // Legenda
                                VStack(alignment: .leading, spacing: 8) {
                                    StatsLegendItem(color: .green, text: "0 - 60 km/h (City)")
                                    StatsLegendItem(color: .blue, text: "61 - 90 km/h (Road)")
                                    StatsLegendItem(color: .yellow, text: "91 - 120 km/h (Highway)")
                                    StatsLegendItem(color: .orange, text: "121 - 150 km/h (Fast)")
                                    StatsLegendItem(color: .red, text: "> 150 km/h (Extreme)")
                                }
                                .padding(.leading, 10)
                            }
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
                    .minimumScaleFactor(0.8)
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
