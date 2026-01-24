//
//  FuelGeneralStatsView.swift
//  MyCar
//
//  Created by Dinis Santos on 16/01/2026.
//

import SwiftUI

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
                
                // 1. Header do Carro
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
                    Image(systemName: "gearshape")
                        .foregroundStyle(.blue)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                
                // (SECÇÃO DE POSTOS REMOVIDA AQUI)
                
                // 2. Resumo de Combustível (Dados Reais)
                VStack(alignment: .leading, spacing: 15) {
                    Text("Fuel Summary")
                        .font(.headline)
                    
                    // Cálculos rápidos
                    let avgConsumption = calculateAvgConsumption(logs: car.fuelLogs)
                    let lastLog = car.fuelLogs.first
                    
                    StatsRowItem(
                        icon: "drop.fill", color: .blue,
                        value: String(format: "%.2f L/100km", avgConsumption),
                        label: "Average Consumption"
                    )
                    
                    StatsRowItem(
                        icon: "fuelpump.fill", color: .green,
                        value: lastLog != nil ? String(format: "%.2f L", lastLog!.liters) : "--",
                        label: "Last Refuel Volume"
                    )
                    
                    StatsRowItem(
                        icon: "eurosign.circle.fill", color: .red,
                        value: lastLog != nil ? String(format: "%.3f €", lastLog!.pricePerLiter) : "--",
                        label: "Last Price/L"
                    )
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                
                // 3. Botões de Navegação (Estatísticas e Gráficos)
                VStack(spacing: 10) {
                    NavigationLink(destination: FuelDetailedStatsView(car: car)) {
                        HStack {
                            Image(systemName: "chart.xyaxis.line")
                            Text("Statistics")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        .foregroundStyle(.white)
                    }
                    
                    // Botão Gráficos (Placeholder por agora)
                    Button {} label: {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("Charts (Coming Soon)")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        .foregroundStyle(.gray)
                    }
                    .disabled(true)
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black)
    }
    
    // Função auxiliar simples para consumo
    func calculateAvgConsumption(logs: [FuelLog]) -> Double {
        // Lógica simplificada: Total Litros / Total Km * 100
        // Para ser exato precisaria da distância ENTRE abastecimentos, mas isto serve de aproximação global
        guard logs.count >= 2, let first = logs.last, let last = logs.first else { return 0 }
        
        let totalDist = last.odometer - first.odometer
        let totalLiters = logs.dropLast().reduce(0) { $0 + $1.liters } // Ignora o primeiro abastecimento da história (não tem dist anterior)
        
        if totalDist > 0 {
            return (totalLiters / totalDist) * 100
        }
        return 0
    }
}

// Subviews Visuais
struct StatsRowItem: View {
    let icon: String
    let color: Color
    let value: String
    let label: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value).bold()
            Spacer()
            Text(label).font(.caption).foregroundStyle(.gray)
        }
    }
}
