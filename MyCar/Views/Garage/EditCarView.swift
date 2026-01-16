import SwiftUI
import PhotosUI

struct EditCarView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: AppViewModel
    
    // O carro original que estamos a editar
    var carToEdit: Car
    
    // Estados locais para edição (Strings facilitam a edição em TextFields)
    @State private var make: String
    @State private var model: String
    @State private var year: String
    @State private var licensePlate: String
    @State private var kilometers: String
    @State private var fuelType: String
    
    // Novos campos técnicos
    @State private var tankCapacity: String
    @State private var horsepower: String
    @State private var displacement: String
    
    // Imagem
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    let fuelTypes = ["Petrol", "Diesel", "Electric", "Hybrid", "LPG"]
    
    init(viewModel: AppViewModel, car: Car) {
        self.viewModel = viewModel
        self.carToEdit = car
        
        // Inicializa os estados com os valores atuais do carro
        _make = State(initialValue: car.make)
        _model = State(initialValue: car.model)
        _year = State(initialValue: car.year)
        _licensePlate = State(initialValue: car.licensePlate)
        _kilometers = State(initialValue: String(Int(car.kilometers)))
        _fuelType = State(initialValue: car.fuelType)
        _selectedImageData = State(initialValue: car.imageData)
        
        // Inicializa os novos campos (convertendo números para String)
        _tankCapacity = State(initialValue: String(Int(car.tankCapacity)))
        _horsepower = State(initialValue: String(car.horsepower))
        _displacement = State(initialValue: String(car.displacement))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // FOTO
                Section {
                    HStack {
                        Spacer()
                        if let data = selectedImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "car.circle.fill")
                                .resizable()
                                .foregroundStyle(.gray)
                                .frame(width: 100, height: 100)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Change Photo", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // DADOS GERAIS
                Section(header: Text("Car Details")) {
                    TextField("Make (e.g. Ford)", text: $make)
                    TextField("Model (e.g. Focus)", text: $model)
                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)
                    TextField("License Plate", text: $licensePlate)
                }
                
                // DADOS TÉCNICOS
                Section(header: Text("Technical Specs")) {
                    Picker("Fuel Type", selection: $fuelType) {
                        ForEach(fuelTypes, id: \.self) { type in Text(type) }
                    }
                    
                    HStack {
                        Text("Odometer (km)")
                        Spacer()
                        TextField("0", text: $kilometers)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Tank Capacity (L)")
                        Spacer()
                        TextField("0", text: $tankCapacity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Horsepower (hp)")
                        Spacer()
                        TextField("0", text: $horsepower)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Displacement (cc)")
                        Spacer()
                        TextField("0", text: $displacement)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // BOTÃO DE APAGAR
                Section {
                    Button(role: .destructive) {
                        deleteCar()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Car")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(make.isEmpty || model.isEmpty)
                }
            }
            .onChange(of: selectedItem) {
                Task {
                    if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
    }
    
    func saveChanges() {
        var updatedCar = carToEdit
        
        updatedCar.make = make
        updatedCar.model = model
        updatedCar.year = year
        updatedCar.licensePlate = licensePlate
        updatedCar.fuelType = fuelType
        updatedCar.imageData = selectedImageData
        
        // Converter Strings para Números
        updatedCar.kilometers = Double(kilometers) ?? 0
        updatedCar.tankCapacity = Double(tankCapacity) ?? 0
        updatedCar.horsepower = Int(horsepower) ?? 0
        updatedCar.displacement = Int(displacement) ?? 0
        
        viewModel.updateCar(updatedCar)
        dismiss()
    }
    
    func deleteCar() {
        // Encontra o índice e apaga
        if let index = viewModel.myCars.firstIndex(where: { $0.id == carToEdit.id }) {
            viewModel.deleteCar(at: IndexSet(integer: index))
            dismiss()
        }
    }
}
