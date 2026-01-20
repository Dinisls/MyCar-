import SwiftUI

struct EditFuelView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: AppViewModel
    
    var carID: UUID
    var logToEdit: FuelLog
    var tankCapacity: Double
    
    enum Field { case odometer, trip, liters, price, total }
    @FocusState private var focusedField: Field?
    
    // MODO DE ENTRADA
    enum InputMode: String, CaseIterable {
        case odometer = "Total Odometer"
        case trip = "Trip Distance"
    }
    @State private var inputMode: InputMode = .odometer
    
    @State private var date: Date
    @State private var odometer: String
    @State private var tripDistance: String // Novo estado
    @State private var liters: String
    @State private var pricePerLiter: String
    @State private var totalCost: String
    @State private var selectedFuelType: String
    @State private var fuelLevelBefore: Double
    @State private var isFullTank: Bool
    @State private var showTankLevel: Bool
    
    let fuelTypes = ["Petrol", "Diesel", "Electric", "Hybrid", "LPG"]
    
    init(viewModel: AppViewModel, carID: UUID, log: FuelLog, tankCapacity: Double) {
        self.viewModel = viewModel
        self.carID = carID
        self.logToEdit = log
        self.tankCapacity = tankCapacity
        
        _date = State(initialValue: log.date)
        _odometer = State(initialValue: String(Int(log.odometer)))
        
        // Inicializa a distância de viagem se existir
        if let dist = log.distanceTraveled {
            _tripDistance = State(initialValue: String(format: "%.1f", dist))
        } else {
            _tripDistance = State(initialValue: "")
        }
        
        _liters = State(initialValue: String(format: "%.2f", log.liters))
        _pricePerLiter = State(initialValue: String(format: "%.3f", log.pricePerLiter))
        _totalCost = State(initialValue: String(format: "%.2f", log.totalCost))
        _selectedFuelType = State(initialValue: log.fuelType)
        _fuelLevelBefore = State(initialValue: log.fuelLevelBefore)
        _isFullTank = State(initialValue: log.isFullTank)
        _showTankLevel = State(initialValue: log.fuelLevelAfter != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("General Info")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Input Mode", selection: $inputMode) {
                        ForEach(InputMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 5)
                    
                    if inputMode == .odometer {
                        TextField("Odometer (km)", text: $odometer)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .odometer)
                    } else {
                        HStack {
                            Text("Trip Distance")
                            Spacer()
                            TextField("e.g. 500", text: $tripDistance)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .trip)
                                .foregroundStyle(.blue)
                        }
                        // Nota explicativa
                        Text("Edits to trip distance will adjust the total odometer relative to the previous log.")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
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
        
        // CALCULA ODÓMETRO FINAL
        var finalOdometer: Double = 0.0
        
        if inputMode == .odometer {
            finalOdometer = Double(odometer) ?? 0
        } else {
            // MODO EDIÇÃO INTELIGENTE
            // Se estamos a editar por "Trip Distance", precisamos saber o odómetro base.
            // Base = OdómetroRegistado - DistânciaRegistada
            let oldTotal = logToEdit.odometer
            let oldTrip = logToEdit.distanceTraveled ?? 0
            let baseOdometer = oldTotal - oldTrip
            
            let newTrip = Double(tripDistance.replacingOccurrences(of: ",", with: ".")) ?? 0
            finalOdometer = baseOdometer + newTrip
        }
        
        let updatedLog = FuelLog(
            id: logToEdit.id,
            date: date,
            odometer: finalOdometer,
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
