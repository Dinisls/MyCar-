//
//  AddServiceView.swift
//  MyCar
//
//  Created by Dinis Santos on 04/02/2026.
//


import SwiftUI

struct AddServiceView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: AppViewModel
    var carID: UUID
    
    @State private var date = Date()
    @State private var type = "Service"
    @State private var cost = ""
    @State private var odometer = ""
    @State private var notes = ""
    
    let serviceTypes = ["Service", "Oil", "Tires", "Brakes", "Inspection", "Repair", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Type", selection: $type) {
                        ForEach(serviceTypes, id: \.self) { t in Text(t).tag(t) }
                    }
                }
                
                Section {
                    TextField("Cost (€)", text: $cost)
                        .keyboardType(.decimalPad)
                    
                    TextField("Odometer (km)", text: $odometer)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Add Service")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveService()
                    }
                    .disabled(cost.isEmpty)
                }
            }
        }
    }
    
    func saveService() {
        let costValue = Double(cost.replacingOccurrences(of: ",", with: ".")) ?? 0
        let odoValue = Double(odometer) ?? 0
        
        let newService = ServiceLog(
            date: date,
            type: type,
            cost: costValue,
            odometer: odoValue,
            notes: notes
        )
        
        viewModel.addServiceLog(newService, to: carID)
        dismiss()
    }
}