//
//  ServiceHistoryView.swift
//  MyCar
//
//  Created by Dinis Santos on 04/02/2026.
//


import SwiftUI

struct ServiceHistoryView: View {
    var viewModel: AppViewModel
    var car: Car
    
    @State private var showingAddService = false
    
    var body: some View {
        List {
            // Resumo de Gastos
            Section {
                let totalCost = car.serviceLogs.reduce(0) { $0 + $1.cost }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Maintenance")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text(String(format: "%.2f €", totalCost))
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange.opacity(0.8))
                }
                .padding(.vertical, 8)
            }
            
            // Lista
            Section(header: Text("History")) {
                if car.serviceLogs.isEmpty {
                    Text("No records yet.")
                        .foregroundStyle(.gray)
                } else {
                    ForEach(car.serviceLogs) { log in
                        ServiceRow(log: log)
                    }
                    .onDelete(perform: deleteService)
                }
            }
        }
        .navigationTitle("Maintenance")
        .toolbar {
            Button(action: { showingAddService = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAddService) {
            AddServiceView(viewModel: viewModel, carID: car.id)
        }
    }
    
    func deleteService(at offsets: IndexSet) {
        viewModel.deleteServiceLog(at: offsets, from: car.id)
    }
}

struct ServiceRow: View {
    let log: ServiceLog
    
    var body: some View {
        HStack(alignment: .top) {
            // Ícone baseada no tipo
            ZStack {
                Circle().fill(Color.orange.opacity(0.1)).frame(width: 40, height: 40)
                Image(systemName: getIcon(for: log.type))
                    .foregroundStyle(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(log.type).font(.headline).foregroundStyle(.primary)
                Text(log.date.formatted(date: .numeric, time: .omitted))
                    .font(.caption).foregroundStyle(.gray)
                if !log.notes.isEmpty {
                    Text(log.notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "%.2f €", log.cost))
                    .bold()
                    .foregroundStyle(.primary)
                Text("\(Int(log.odometer)) km")
                    .font(.caption).foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    func getIcon(for type: String) -> String {
        switch type {
        case "Oil": return "drop.fill"
        case "Tires": return "tire"
        case "Inspection": return "checkmark.seal.fill"
        case "Repair": return "hammer.fill"
        default: return "wrench.fill"
        }
    }
}