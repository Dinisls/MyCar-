import SwiftUI

struct AddFuelView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: AppViewModel
    
    // Dados recebidos
    var carID: UUID
    var currentKm: Double
    var defaultFuelType: String
    var tankCapacity: Double
    
    // Identificadores de foco
    enum Field { case odometer, liters, price, total }
    @FocusState private var focusedField: Field?
    
    // Estados do Formulário
    @State private var date = Date()
    @State private var odometer: String = ""
    @State private var selectedFuelType = "Petrol"
    
    // Estados de Combustível
    @State private var liters: String = ""
    @State private var pricePerLiter: String = ""
    @State private var totalCost: String = ""
    
    // Estados de Tanque
    @State private var isFullTank: Bool = true
    @State private var showTankLevel: Bool = false // <--- NOVO TOGGLE (Desligado por defeito)
    @State private var fuelLevelBefore: Double = 0.25
    
    let fuelTypes = ["Petrol", "Diesel", "Electric", "Hybrid", "LPG"]
    
    init(viewModel: AppViewModel, carID: UUID, currentKm: Double, defaultFuelType: String, tankCapacity: Double) {
        self.viewModel = viewModel
        self.carID = carID
        self.currentKm = currentKm
        self.defaultFuelType = defaultFuelType
        self.tankCapacity = tankCapacity
        
        _selectedFuelType = State(initialValue: defaultFuelType)
        _odometer = State(initialValue: String(Int(currentKm)))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // SEÇÃO 1: Dados Gerais
                Section(header: Text("General Info")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    HStack {
                        Text("Odometer (km)")
                        Spacer()
                        TextField("Km", text: $odometer)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .odometer)
                    }
                }
                
                // SEÇÃO 2: Combustível e Custos
                Section(header: Text("Fuel Details")) {
                    Picker("Fuel Type", selection: $selectedFuelType) {
                        ForEach(fuelTypes, id: \.self) { type in Text(type).tag(type) }
                    }
                    
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
                        Text("Price / Liter (€)")
                        Spacer()
                        TextField("0.000", text: $pricePerLiter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.blue)
                            .focused($focusedField, equals: .price)
                            .onChange(of: pricePerLiter) { performCalculation() }
                    }
                    
                    HStack {
                        Text("Total Cost (€)")
                            .bold()
                        Spacer()
                        TextField("0.00", text: $totalCost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.green).bold()
                            .focused($focusedField, equals: .total)
                            .onChange(of: totalCost) { performCalculation() }
                    }
                }
                
                // SEÇÃO 3: Opções do Tanque
                Section {
                    Toggle(isOn: $isFullTank) {
                        Text("Full Tank")
                    }
                    
                    // NOVO TOGGLE: Mostrar ou esconder níveis
                    Toggle(isOn: $showTankLevel) {
                        Text("Track Tank Level") // "Definir nível do tanque"
                    }
                }
                
                // SEÇÃO 4: Níveis (Só aparece se o toggle estiver ativo)
                if showTankLevel {
                    Section(header: Text("Tank Levels")) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Level Before Refuel")
                                Spacer()
                                Text("\(Int(fuelLevelBefore * 100))%")
                                    .bold()
                                    .foregroundStyle(.orange)
                            }
                            Slider(value: $fuelLevelBefore, in: 0...1, step: 0.05)
                        }
                        
                        HStack {
                            Text("Level After Refuel")
                            Spacer()
                            let levelAfter = calculateLevelAfter()
                            Text("\(Int(levelAfter * 100))%")
                                .bold()
                                .foregroundStyle(levelAfter > 1.0 ? .red : .green)
                            
                            if isFullTank {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                        
                        ProgressView(value: min(calculateLevelAfter(), 1.0))
                            .tint(calculateLevelAfter() > 1.0 ? .red : .green)
                    }
                }
            }
            .navigationTitle("Add Refuel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveLog() }
                    .disabled(liters.isEmpty || totalCost.isEmpty)
                }
                ToolbarItem(placement: .keyboard) { Button("Done") { focusedField = nil } }
            }
        }
    }
    
    // MARK: - Lógica
    
    func calculateLevelAfter() -> Double {
        if isFullTank { return 1.0 }
        let l = Double(liters.replacingOccurrences(of: ",", with: ".")) ?? 0
        let volumeBefore = tankCapacity * fuelLevelBefore
        let volumeAfter = volumeBefore + l
        return tankCapacity > 0 ? volumeAfter / tankCapacity : 0
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
    
    func saveLog() {
        // Se o utilizador não quis controlar o nível, guardamos nil ou 0 no calculation
        let finalLevel = showTankLevel ? calculateLevelAfter() : nil
        
        let newLog = FuelLog(
            date: date,
            odometer: Double(odometer) ?? currentKm,
            liters: Double(liters.replacingOccurrences(of: ",", with: ".")) ?? 0,
            pricePerLiter: Double(pricePerLiter.replacingOccurrences(of: ",", with: ".")) ?? 0,
            totalCost: Double(totalCost.replacingOccurrences(of: ",", with: ".")) ?? 0,
            fuelType: selectedFuelType,
            fuelLevelBefore: showTankLevel ? fuelLevelBefore : 0, // Guarda 0 se inativo
            fuelLevelAfter: finalLevel,
            isFullTank: isFullTank
        )
        
        viewModel.addFuelLog(newLog, to: carID)
        dismiss()
    }
}
