import SwiftUI
import PhotosUI

struct GarageView: View {
    var viewModel: AppViewModel
    
    // Estado para controlar a Sheet de adicionar
    @State private var showingAddCar = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.myCars.isEmpty {
                    // Ecrã Vazio
                    VStack(spacing: 20) {
                        Image(systemName: "car.2.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                        Text("Garage Empty")
                            .font(.title2.bold())
                        Text("Add your first car to start tracking.")
                            .foregroundStyle(.gray)
                    }
                } else {
                    // Lista de Carros
                    List {
                        ForEach(viewModel.myCars) { car in
                            // Link para o detalhe (que permite editar)
                            NavigationLink(destination: CarDetailView(viewModel: viewModel, car: car)) {
                                GarageCarRow(car: car)
                            }
                        }
                        .onDelete(perform: deleteCar)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Garage")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddCar = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            // SHEET PARA ADICIONAR CARRO (Formulário Completo)
            .sheet(isPresented: $showingAddCar) {
                AddCarFormView(viewModel: viewModel)
            }
        }
    }
    
    func deleteCar(at offsets: IndexSet) {
        viewModel.deleteCar(at: offsets)
    }
}

// MARK: - SUBVIEW: Formulário de Adicionar Carro
struct AddCarFormView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: AppViewModel
    
    // Estados do Formulário
    @State private var make = ""
    @State private var model = ""
    @State private var year = ""
    @State private var licensePlate = ""
    @State private var kilometers = ""
    @State private var fuelType = "Petrol"
    
    // Novos Campos Técnicos (String para facilitar input)
    @State private var tankCapacity = ""
    @State private var horsepower = ""
    @State private var displacement = ""
    
    // Imagem
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    let fuelTypes = ["Petrol", "Diesel", "Electric", "Hybrid", "LPG"]
    
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
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "car.circle.fill")
                                .resizable()
                                .foregroundStyle(.gray)
                                .frame(width: 80, height: 80)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Add Photo", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // DADOS GERAIS
                Section(header: Text("General Info")) {
                    TextField("Make (e.g. BMW)", text: $make)
                    TextField("Model (e.g. Series 3)", text: $model)
                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)
                    TextField("License Plate", text: $licensePlate)
                }
                
                // DADOS TÉCNICOS
                Section(header: Text("Technical Specs")) {
                    Picker("Fuel Type", selection: $fuelType) {
                        ForEach(fuelTypes, id: \.self) { type in Text(type).tag(type) }
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
            }
            .navigationTitle("New Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCar()
                    }
                    .disabled(make.isEmpty || model.isEmpty)
                }
            }
            // Lógica da Foto
            .onChange(of: selectedItem) {
                Task {
                    if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
    }
    
    func saveCar() {
        // Conversão de Strings para Números com segurança
        let kmValue = Double(kilometers) ?? 0
        let tankValue = Double(tankCapacity) ?? 0
        let hpValue = Int(horsepower) ?? 0
        let ccValue = Int(displacement) ?? 0
        
        let newCar = Car(
            make: make,
            model: model,
            year: year,
            licensePlate: licensePlate,
            kilometers: kmValue,
            fuelType: fuelType,
            tankCapacity: tankValue,    // Corrigido: Agora usa tankCapacity
            horsepower: hpValue,        // Corrigido: Novo campo
            displacement: ccValue,      // Corrigido: Novo campo
            imageData: selectedImageData
        )
        
        viewModel.addCar(newCar)
        dismiss()
    }
}

// MARK: - SUBVIEW: Linha da Lista de Carros
struct GarageCarRow: View {
    let car: Car
    
    var body: some View {
        HStack(spacing: 12) {
            // Imagem do Carro
            if let image = car.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    Color.gray.opacity(0.2)
                    Image(systemName: "car.fill")
                        .foregroundStyle(.gray)
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            }
            
            // Textos
            VStack(alignment: .leading, spacing: 4) {
                Text("\(car.make) \(car.model)")
                    .font(.headline)
                
                Text(car.licensePlate.isEmpty ? car.year : car.licensePlate)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // KMs atuais
            Text("\(Int(car.kilometers)) km")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }
}
