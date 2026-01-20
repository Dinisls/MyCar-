import SwiftUI

struct SettingsView: View {
    // Tem de ter esta linha para receber o que enviámos no MainTabView
    var viewModel: AppViewModel
    
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Data Management") {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.gray)
                    }
                    Text("MyCar Project by DLS inc")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Everything?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.resetAllData()
                }
            } message: {
                Text("This will delete all trips, cars, and fuel logs. This action cannot be undone.")
            }
        }
    }
}
