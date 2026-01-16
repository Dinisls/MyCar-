import SwiftUI

struct SettingsView: View {
    // Precisamos do ViewModel para poder chamar a função de reset
    var viewModel: AppViewModel
    
    // Estado para controlar se o alerta aparece ou não
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Secção 1: Informações da App
                Section(header: Text("About")) {
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundStyle(.blue)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.gray)
                    }
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("Developer")
                        Spacer()
                        // ALTERAÇÃO AQUI:
                        Text("DLS inc")
                            .foregroundStyle(.gray)
                    }
                }
                
                // Secção 2: ZONA DE PERIGO (Apagar Dados)
                Section(header: Text("Data Management")) {
                    Button(role: .destructive) {
                        // Ao clicar, ativamos o alerta
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Reset All Data")
                        }
                    }
                }
                
                Section(footer: Text("Deleting all data will remove all your trips, cars, and fuel logs permanently.")) {
                    // Espaço vazio apenas para mostrar o footer explicativo
                }
            }
            .navigationTitle("Settings")
            .background(Color.black)
            
            // O ALERTA DE CONFIRMAÇÃO
            .alert("Are you sure?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Everything", role: .destructive) {
                    // Chama a função que limpa tudo
                    withAnimation {
                        viewModel.resetAllData()
                    }
                }
            } message: {
                Text("This action cannot be undone. All your cars, fuel logs, and trip history will be permanently deleted.")
            }
        }
    }
}
