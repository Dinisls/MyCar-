import SwiftUI

struct MainTabView: View {
    // Inicializa o ViewModel uma única vez aqui
    @State private var viewModel = AppViewModel()
    
    var body: some View {
        TabView {
            // 1. Tracking (Condução)
            TrackingView(viewModel: viewModel)
                .tabItem {
                    Label("Tracking", systemImage: "car.fill")
                }
            // 4. Trips (Menu: History | Stats)
            TripsTabView(viewModel: viewModel)
                .tabItem {
                    Label("Trips", systemImage: "map.circle.fill")
                }
            
            // 2. Garage (Gestão de Carros)
            GarageView(viewModel: viewModel)
                .tabItem {
                    Label("Garage", systemImage: "house.fill")
                }
            
            // 3. Fuel (Menu: Logs | Stats)
            FuelTabView(viewModel: viewModel)
                .tabItem {
                    Label("Fuel", systemImage: "fuelpump.fill")
                }
        
            
            // 5. Settings (Definições e Reset)
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(.dark)
        .tint(.blue)
    }
}
