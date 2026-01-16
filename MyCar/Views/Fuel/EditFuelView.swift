import SwiftUI

struct EditFuelView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: AppViewModel
    
    var carID: UUID
    var logToEdit: FuelLog
    var tankCapacity: Double
    
    enum Field { case odometer, liters, price, total }
    @FocusState private var focusedField: Field?
    
    @State private var date: Date
    @State private var odometer: String
    @State private var liters: String
    @State private var pricePerLiter: String
    @State private var totalCost: String
    @State private var selectedFuelType: String
    @State private var fuelLevelBefore: Double
    @State private var isFullTank: Bool
    @State private var showTankLevel: Bool // <--- NOVO
    
    let fuelTypes = ["Petrol", "Diesel", "Electric", "Hybrid", "LPG"]
    
    init(viewModel: AppViewModel, carID: UUID, log: FuelLog, tankCapacity: Double) {
        self.viewModel = viewModel
        self.carID = carID
        self.logToEdit = log
        self.tankCapacity = tankCapacity
        
        _date = State(initialValue: log.date)
        _odometer = State(initialValue: String(Int(log.odometer)))
        _liters = State(initialValue: String(format: "%.2f", log.liters))
        _pricePerLiter = State(initialValue: String(format: "%.3f", log.pricePerLiter))
        _totalCost = State(initialValue: String(format: "%.2f", log.totalCost))
        _selectedFuelType = State(initialValue: log.fuelType)
        _fuelLevelBefore = State(initialValue: log.fuelLevelBefore)
        _isFullTank = State(initialValue: log.isFullTank)
        
        // Se fuelLevelAfter existir, assumimos que o utilizador estava a usar essa feature
        _showTankLevel = State(initialValue: log.fuelLevelAfter != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("General Info")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Odometer (km)", text: $odometer)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .odometer)
                }
                
                Section(header: Text("Fuel Details")) {
                    Picker("Fuel Type", selection: $selectedFuelType) {
                        ForEach(fuelTypes, id: \.self) { type in Text(type).tag(type) }
                    }
                    
                    Toggle(isOn: $isFullTank) {
                        Text("Full Tank")
                    }
                    
                    Toggle(isOn: $showTankLevel) {
                        Text("Track Tank Level")
                    }
                }
                
                // Só mostra se o toggle estiver ativo
                if showTankLevel {
                    Section {
                        VStack(alignment: .leading) {
                            Text("Tank Level Before: \(Int(fuelLevelBefore * 100))%")
                                .font(.caption).foregroundStyle(.gray)
                            Slider(value: $fuelLevelBefore, in: 0...1, step: 0.05)
                        }
                    }
                }
                
                Section(header: Text("Cost & Volume (Auto-Calc)")) {
                    HStack {
                        Text("Liters")
                        Spacer()
                        TextField("0.0", text: $liters)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .liters)
                            .onChange(of: liters) { performCalculation() }
                    }
                    HStack {
                        Text("Total (€)")
                        Spacer()
                        TextField("0.00", text: $totalCost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .total)
                            .foregroundStyle(.green)
                            .onChange(of: totalCost) { performCalculation() }
                    }
                    HStack {
                        Text("Price/L (€)")
                        Spacer()
                        TextField("0.000", text: $pricePerLiter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .price)
                            .foregroundStyle(.blue)
                            .onChange(of: pricePerLiter) { performCalculation() }
                    }
                }
            }
            .navigationTitle("Edit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { saveChanges() } }
                ToolbarItem(placement: .keyboard) { Button("Done") { focusedField = nil } }
            }
        }
    }
    
    func performCalculation() {
        let l = Double(liters.replacingOccurrences(of: ",", with: ".")) ?? 0
        let p = Double(pricePerLiter.replacingOccurrences(of: ",", with: ".")) ?? 0
        let t = Double(totalCost.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        if focusedField == .liters {
            if p > 0 { totalCost = String(format: "%.2f", l * p) }
            else if t > 0 && l > 0 { pricePerLiter = String(format: "%.3f", t / l) }
        } else if focusedField == .total {
            if l > 0 { pricePerLiter = String(format: "%.3f", t / l) }
            else if p > 0 { liters = String(format: "%.2f", t / p) }
        } else if focusedField == .price {
            if l > 0 { totalCost = String(format: "%.2f", l * p) }
            else if t > 0 && p > 0 { liters = String(format: "%.2f", t / p) }
        }
    }
    
    func calculateLevelAfter() -> Double? {
        if !showTankLevel { return nil }
        if isFullTank { return 1.0 }
        let l = Double(liters.replacingOccurrences(of: ",", with: ".")) ?? 0
        let volumeBefore = tankCapacity * fuelLevelBefore
        let volumeAfter = volumeBefore + l
        return tankCapacity > 0 ? (volumeAfter / tankCapacity) : 0
    }
    
    func saveChanges() {
        let finalLevel = calculateLevelAfter()
        
        let updatedLog = FuelLog(
            id: logToEdit.id,
            date: date,
            odometer: Double(odometer) ?? 0,
            liters: Double(liters.replacingOccurrences(of: ",", with: ".")) ?? 0,
            pricePerLiter: Double(pricePerLiter.replacingOccurrences(of: ",", with: ".")) ?? 0,
            totalCost: Double(totalCost.replacingOccurrences(of: ",", with: ".")) ?? 0,
            fuelType: selectedFuelType,
            fuelLevelBefore: showTankLevel ? fuelLevelBefore : 0,
            fuelLevelAfter: finalLevel,
            isFullTank: isFullTank
        )
        
        viewModel.updateFuelLog(updatedLog, for: carID)
        dismiss()
    }
}
