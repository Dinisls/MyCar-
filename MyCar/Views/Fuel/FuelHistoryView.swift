import SwiftUI

struct FuelHistoryView: View {
    @Bindable var viewModel: AppViewModel
    var car: Car
    
    @State private var showingAddFuel = false
    @State private var logToEdit: FuelLog?
    
    var body: some View {
        List {
            // 1. SECÇÃO DE RESUMO (TOPO)
            Section {
                HStack(spacing: 16) {
                    
                    // Custo Total (Simples soma)
                    let totalSpent = car.fuelLogs.reduce(0) { $0 + $1.totalCost }
                    
                    // Cálculo da Média CORRIGIDA (usa a função do ViewModel)
                    let avgConsumption = viewModel.getRealAverageConsumption(for: car)
                    
                    SummaryCard(
                        title: "Total Cost",
                        value: "€\(String(format: "%.2f", totalSpent))",
                        icon: "eurosign.circle.fill",
                        color: .green
                    )
                    
                    SummaryCard(
                        title: "Avg. Consumption",
                        value: String(format: "%.1f L/100km", avgConsumption),
                        icon: "fuelpump.fill",
                        color: .orange
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .padding(.vertical, 10)
            }
            
            // 2. LISTA DE REGISTOS
            Section(header: Text("History (\(car.fuelLogs.count))")) {
                if car.fuelLogs.isEmpty {
                    Text("No records yet. Tap + to add.")
                        .foregroundStyle(.gray)
                } else {
                    ForEach(car.fuelLogs) { log in
                        Button {
                            logToEdit = log
                        } label: {
                            FuelLogRow(log: log)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deleteLog)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Fuel History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddFuel = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // SHEET 1: ADICIONAR
        .sheet(isPresented: $showingAddFuel) {
            AddFuelView(
                viewModel: viewModel,
                carID: car.id,
                currentKm: car.kilometers,
                defaultFuelType: car.fuelType,
                tankCapacity: car.tankCapacity
            )
        }
        // SHEET 2: EDITAR
        .sheet(item: $logToEdit) { log in
            EditFuelView(
                viewModel: viewModel,
                carID: car.id,
                log: log,
                tankCapacity: car.tankCapacity
            )
        }
    }
    
    func deleteLog(at offsets: IndexSet) {
        viewModel.deleteFuelLog(at: offsets, from: car.id)
    }
}

// MARK: - COMPONENTES VISUAIS

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Spacer()
            }
            Text(value).font(.title2.bold()).minimumScaleFactor(0.8)
            Text(title).font(.caption).foregroundStyle(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct FuelLogRow: View {
    let log: FuelLog
    
    var body: some View {
        VStack(spacing: 0) {
            
            // HEADER
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(.white)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Group {
                            if let name = log.stationName, !name.isEmpty {
                                Text(String(name.prefix(1))).font(.headline).foregroundStyle(.red)
                            } else {
                                Image(systemName: "fuelpump.fill").font(.subheadline).foregroundStyle(.blue)
                            }
                        }
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.date.formatted(date: .numeric, time: .omitted))
                        .font(.headline).foregroundStyle(.white)
                    Text(String(format: "%.2f €", log.totalCost))
                        .font(.title3.bold()).foregroundStyle(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(log.odometer)) km").font(.headline).foregroundStyle(.white)
                    if let dist = log.distanceTraveled {
                        Text("\(Int(dist)) km").font(.subheadline).foregroundStyle(.gray)
                    } else {
                        Text("--- km").font(.subheadline).foregroundStyle(.gray)
                    }
                }
            }
            .padding(.bottom, 10)
            
            Divider().background(Color.gray.opacity(0.3)).padding(.bottom, 10)
            
            // MEIO
            HStack {
                Image(systemName: "drop.fill").foregroundStyle(.blue).font(.caption)
                Text(String(format: "%.2f L", log.liters)).foregroundStyle(.white)
                Image(systemName: "arrow.right").font(.caption).foregroundStyle(.gray)
                Text(String(format: "%.3f €/L", log.pricePerLiter)).foregroundStyle(.white)
                Text("(\(log.fuelType))").font(.caption).foregroundStyle(.gray)
                Spacer()
            }
            .padding(.bottom, 8)
            
            // RODAPÉ
            HStack(spacing: 15) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis").foregroundStyle(.green)
                    if let eff = log.efficiency {
                        Text(String(format: "%.2f l/100km", eff)).bold().foregroundStyle(.green)
                    } else {
                        Text("-- l/100km").foregroundStyle(.gray)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle").foregroundStyle(.gray)
                    if let dist = log.distanceTraveled, dist > 0 {
                        let costPerKm = log.totalCost / dist
                        Text(String(format: "%.2f €/km", costPerKm)).foregroundStyle(.gray)
                    } else {
                        Text("--- €").foregroundStyle(.gray)
                    }
                }
                Spacer()
            }
            
            if let station = log.stationName {
                HStack {
                    Image(systemName: "mappin.and.ellipse").font(.caption).foregroundStyle(.blue)
                    Text(station).font(.caption).foregroundStyle(.white)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
