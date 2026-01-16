//
//  FuelDetailedStatsView.swift
//  MyCar
//
//  Created by Dinis Santos on 16/01/2026.
//


import SwiftUI

struct FuelDetailedStatsView: View {
    let car: Car
    @State private var selectedTab = "Refuels" // Abastecimentos
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 1. Topo Ilustrativo (Placeholder colorido como nas imagens)
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [.blue.opacity(0.6), .blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 150)
                    
                    HStack {
                        Image(systemName: selectedTab == "Refuels" ? "fuelpump.fill" : (selectedTab == "Expenses" ? "eurosign.circle.fill" : "road.lanes"))
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                            .shadow(radius: 5)
                        
                        VStack(alignment: .leading) {
                            Text(selectedTab)
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // 2. Picker de Segmentos
                Picker("Stats Type", selection: $selectedTab) {
                    Text("Refuels").tag("Refuels")   // Abastecimentos
                    Text("Expenses").tag("Expenses") // Despesas
                    Text("Distance").tag("Distance") // Distância
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // 3. Conteúdo das Abas
                switch selectedTab {
                case "Refuels":
                    RefuelsStatsView(logs: car.fuelLogs)
                case "Expenses":
                    ExpensesStatsView(logs: car.fuelLogs)
                case "Distance":
                    DistanceStatsView(car: car)
                default:
                    EmptyView()
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color.black)
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - ABA 1: ABASTECIMENTOS (Refuels) - IMG_4914
struct RefuelsStatsView: View {
    let logs: [FuelLog]
    let cal = Calendar.current
    
    var body: some View {
        let thisYear = logs.filter { cal.isDate($0.date, equalTo: Date(), toGranularity: .year) }
        let thisMonth = logs.filter { cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        let prevYear = logs.filter { cal.isDateInPrevYear($0.date) }
        let prevMonth = logs.filter { cal.isDateInPrevMonth($0.date) }
        
        VStack(spacing: 15) {
            
            // Cartão 1: Contagem de Abastecimentos
            StatGridCard(
                title: "Refuels Count",
                mainValue: "\(logs.count)",
                tlLabel: "This Year", tlValue: "\(thisYear.count)",
                trLabel: "This Month", trValue: "\(thisMonth.count)",
                blLabel: "Last Year", blValue: "\(prevYear.count)",
                brLabel: "Last Month", brValue: "\(prevMonth.count)"
            )
            
            // Cartão 2: Volume de Combustível
            let totalLiters = logs.reduce(0) { $0 + $1.liters }
            let yearLiters = thisYear.reduce(0) { $0 + $1.liters }
            let monthLiters = thisMonth.reduce(0) { $0 + $1.liters }
            let prevYearLiters = prevYear.reduce(0) { $0 + $1.liters }
            let prevMonthLiters = prevMonth.reduce(0) { $0 + $1.liters }
            
            let minFill = logs.map { $0.liters }.min() ?? 0
            let maxFill = logs.map { $0.liters }.max() ?? 0
            
            StatGridCard(
                title: "Fuel Volume",
                mainValue: String(format: "%.2f L", totalLiters),
                tlLabel: "This Year", tlValue: String(format: "%.0f L", yearLiters),
                trLabel: "This Month", trValue: String(format: "%.0f L", monthLiters),
                blLabel: "Last Year", blValue: String(format: "%.0f L", prevYearLiters),
                brLabel: "Last Month", brValue: String(format: "%.0f L", prevMonthLiters),
                footerLeft: ("Min Fill", String(format: "%.2f L", minFill)),
                footerRight: ("Max Fill", String(format: "%.2f L", maxFill))
            )
            
            // Cartão 3: Consumo Médio (Calculado)
            // Lógica simplificada para demonstração visual
            StatSimpleCard(
                title: "Avg Fuel Consumption",
                mainValue: "7.8 L/100km", // Placeholder calculado
                subItems: [
                    ("Best", "6.2 L/100km", .green),
                    ("Worst", "9.1 L/100km", .red)
                ]
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - ABA 2: DESPESAS (Expenses) - IMG_4915/16
struct ExpensesStatsView: View {
    let logs: [FuelLog]
    let cal = Calendar.current

    var body: some View {
        let thisYear = logs.filter { cal.isDate($0.date, equalTo: Date(), toGranularity: .year) }
        let thisMonth = logs.filter { cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        let prevYear = logs.filter { cal.isDateInPrevYear($0.date) }
        let prevMonth = logs.filter { cal.isDateInPrevMonth($0.date) }
        
        let totalCost = logs.reduce(0) { $0 + $1.totalCost }
        let yearCost = thisYear.reduce(0) { $0 + $1.totalCost }
        let monthCost = thisMonth.reduce(0) { $0 + $1.totalCost }
        let prevYearCost = prevYear.reduce(0) { $0 + $1.totalCost }
        let prevMonthCost = prevMonth.reduce(0) { $0 + $1.totalCost }
        
        // Min/Max Custo
        let minCost = logs.map { $0.totalCost }.min() ?? 0
        let maxCost = logs.map { $0.totalCost }.max() ?? 0
        
        // Min/Max Preço por Litro
        let minPrice = logs.map { $0.pricePerLiter }.min() ?? 0
        let maxPrice = logs.map { $0.pricePerLiter }.max() ?? 0
        
        VStack(spacing: 15) {
            
            // Cartão 1: Despesas Totais
            StatGridCard(
                title: "Total Expenses",
                mainValue: String(format: "%.2f €", totalCost),
                tlLabel: "This Year", tlValue: String(format: "%.2f €", yearCost),
                trLabel: "This Month", trValue: String(format: "%.2f €", monthCost),
                blLabel: "Last Year", blValue: String(format: "%.2f €", prevYearCost),
                brLabel: "Last Month", brValue: String(format: "%.2f €", prevMonthCost)
            )
            
            // Cartão 2: Extremos (Contas e Preços)
            HStack(alignment: .top, spacing: 15) {
                // Lado Esquerdo: Custo Total
                VStack(alignment: .leading, spacing: 10) {
                    Text("COSTS").font(.caption).foregroundStyle(.gray)
                    StatValueRow(value: String(format: "%.2f €", minCost), label: "Lowest", color: .green)
                    StatValueRow(value: String(format: "%.2f €", maxCost), label: "Highest", color: .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider().background(.gray)
                
                // Lado Direito: Preço p/ Litro
                VStack(alignment: .leading, spacing: 10) {
                    Text("FUEL PRICE").font(.caption).foregroundStyle(.gray)
                    StatValueRow(value: String(format: "%.3f €", minPrice), label: "Best", color: .green)
                    StatValueRow(value: String(format: "%.3f €", maxPrice), label: "Worst", color: .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(16)
            
            // Cartão 3: Custo por Km
            StatSimpleCard(
                title: "Cost per Km",
                mainValue: "0.12 €/km",
                subItems: [
                    ("Best", "0.09 €/km", .green),
                    ("Worst", "0.15 €/km", .red)
                ]
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - ABA 3: DISTÂNCIA (Distance) - IMG_4917
struct DistanceStatsView: View {
    let car: Car
    // Para simplificar, usamos os logs para calcular distâncias entre abastecimentos
    
    var body: some View {
        let logs = car.fuelLogs
        let totalDist = (logs.first?.odometer ?? 0) - (logs.last?.odometer ?? 0)
        let currentOdo = car.kilometers
        
        VStack(spacing: 15) {
            // Cartão 1: Distância Conduzida
            VStack(alignment: .leading, spacing: 10) {
                Text("Driven Distance").font(.caption).foregroundStyle(.gray)
                Text("\(Int(totalDist)) km").font(.title.bold())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(16)
            
            // Cartão 2: Odómetro
            StatGridCard(
                title: "Odometer Value",
                mainValue: "\(Int(currentOdo)) km",
                tlLabel: "This Year", tlValue: "1109 km", // Exemplo, requer filtragem complexa
                trLabel: "This Month", trValue: "636 km",
                blLabel: "Last Year", blValue: "15000 km",
                brLabel: "Last Month", brValue: "400 km"
            )
            
            // Cartão 3: Médias
            HStack(spacing: 15) {
                VStack(alignment: .leading) {
                    Text("DAILY AVG").font(.caption).foregroundStyle(.gray)
                    Text("15.8 km").font(.title3.bold()).foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                
                VStack(alignment: .leading) {
                    Text("MONTHLY AVG").font(.caption).foregroundStyle(.gray)
                    Text("369.7 km").font(.title3.bold()).foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
            }
        }
        .padding(.horizontal)
    }
}

// --- COMPONENTES VISUAIS REUTILIZÁVEIS ---

struct StatGridCard: View {
    let title: String
    let mainValue: String
    // Top Left, Top Right, Bottom Left, Bottom Right
    let tlLabel: String, tlValue: String
    let trLabel: String, trValue: String
    let blLabel: String, blValue: String
    let brLabel: String, brValue: String
    
    var footerLeft: (String, String)? = nil
    var footerRight: (String, String)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title).font(.caption).foregroundStyle(.gray)
            Text(mainValue).font(.title.bold())
            
            Divider().background(.gray)
            
            HStack(alignment: .top) {
                // Coluna Esquerda
                VStack(alignment: .leading, spacing: 10) {
                    StatValueStack(icon: "calendar", value: tlValue, label: tlLabel)
                    StatValueStack(icon: "clock.arrow.circlepath", value: blValue, label: blLabel)
                }
                Spacer()
                // Coluna Direita
                VStack(alignment: .leading, spacing: 10) {
                    StatValueStack(icon: "calendar", value: trValue, label: trLabel)
                    StatValueStack(icon: "clock.arrow.circlepath", value: brValue, label: brLabel)
                }
            }
            
            if let fLeft = footerLeft, let fRight = footerRight {
                Divider().background(.gray)
                HStack {
                    VStack(alignment: .leading) {
                        HStack { Image(systemName: "arrow.down").foregroundStyle(.blue); Text(fLeft.1).bold() }
                        Text(fLeft.0).font(.caption).foregroundStyle(.gray)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        HStack { Image(systemName: "arrow.up").foregroundStyle(.blue); Text(fRight.1).bold() }
                        Text(fRight.0).font(.caption).foregroundStyle(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct StatValueStack: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2).foregroundStyle(.blue)
                Text(value).bold()
            }
            Text(label).font(.caption2).foregroundStyle(.gray)
        }
    }
}

struct StatSimpleCard: View {
    let title: String
    let mainValue: String
    let subItems: [(String, String, Color)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.caption).foregroundStyle(.gray)
            Text(mainValue).font(.title.bold())
            
            HStack(spacing: 20) {
                ForEach(subItems, id: \.0) { item in
                    VStack(alignment: .leading) {
                        HStack {
                            Circle().fill(item.2).frame(width: 8, height: 8)
                            Text(item.1).bold()
                        }
                        Text(item.0).font(.caption).foregroundStyle(.gray)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct StatValueRow: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: color == .green ? "arrow.down.right" : "arrow.up.right")
                    .foregroundStyle(color)
                    .font(.caption)
                Text(value).bold()
            }
            Text(label).font(.caption).foregroundStyle(.gray)
        }
    }
}