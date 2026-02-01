import SwiftUI
import Charts

struct FuelGeneralStatsView: View {
    @Bindable var viewModel: AppViewModel
    
    var body: some View {
        Group {
            if viewModel.myCars.isEmpty {
                ContentUnavailableView("No Cars", systemImage: "car", description: Text("Add a car first."))
            } else {
                List {
                    ForEach(viewModel.myCars) { car in
                        NavigationLink(destination: CarFuelDashboard(car: car)) {
                            HStack {
                                Image(systemName: "car.fill")
                                    .padding(8)
                                    .background(.blue)
                                    .clipShape(Circle())
                                    .foregroundStyle(.white)
                                Text("\(car.make) \(car.model)")
                                    .font(.headline)
                            }
                        }
                    }
                }
                .navigationTitle("Fuel Dashboards")
            }
        }
    }
}

// --- DASHBOARD INDIVIDUAL ---
struct CarFuelDashboard: View {
    let car: Car
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 1. HEADER
                HStack {
                    Image(systemName: "car.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("\(car.make) \(car.model)")
                            .font(.title2.bold())
                        Text("\(Int(car.kilometers)) km")
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                
                // 2. RESUMO
                VStack(alignment: .leading, spacing: 15) {
                    Text("Fuel Summary").font(.headline)
                    let avgConsumption = calculateAvgConsumption(logs: car.fuelLogs)
                    let lastLog = car.fuelLogs.first
                    
                    StatsRowItem(icon: "drop.fill", color: .blue, value: String(format: "%.2f L/100km", avgConsumption), label: "Average Consumption")
                    StatsRowItem(icon: "fuelpump.fill", color: .green, value: lastLog != nil ? String(format: "%.2f L", lastLog!.liters) : "--", label: "Last Refuel Volume")
                    StatsRowItem(icon: "eurosign.circle.fill", color: .red, value: lastLog != nil ? String(format: "%.3f €", lastLog!.pricePerLiter) : "--", label: "Last Price/L")
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                
                // 3. GRÁFICO DE EFICIÊNCIA (ATUALIZADO)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Efficiency Trend").font(.headline)
                    
                    if car.fuelLogs.count < 2 {
                        Text("Need at least 2 logs to show chart").font(.caption).foregroundStyle(.gray)
                    } else {
                        Chart {
                            ForEach(car.fuelLogs.reversed()) { log in
                                if let eff = log.efficiency {
                                    LineMark(
                                        x: .value("Date", log.date),
                                        y: .value("L/100km", eff)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(.blue)
                                    
                                    PointMark(
                                        x: .value("Date", log.date),
                                        y: .value("L/100km", eff)
                                    )
                                    .foregroundStyle(.blue)
                                }
                            }
                        }
                        .frame(height: 200)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                
                // 4. BOTÃO PARA DETALHES
                NavigationLink(destination: FuelDetailedStatsView(car: car)) {
                    HStack {
                        Image(systemName: "list.bullet.clipboard")
                        Text("View Detailed Logs & Stats")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .background(Color.black)
    }
    
    // Função auxiliar (igual à anterior)
    func calculateAvgConsumption(logs: [FuelLog]) -> Double {
        guard logs.count >= 2, let first = logs.last, let last = logs.first else { return 0 }
        let totalDist = last.odometer - first.odometer
        let totalLiters = logs.dropLast().reduce(0) { $0 + $1.liters }
        return totalDist > 0 ? (totalLiters / totalDist) * 100 : 0
    }
}

struct StatsRowItem: View {
    let icon: String; let color: Color; let value: String; let label: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).bold()
            Spacer()
            Text(label).font(.caption).foregroundStyle(.gray)
        }
    }
}
