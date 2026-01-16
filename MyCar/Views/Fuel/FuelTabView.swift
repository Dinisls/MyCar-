import SwiftUI

struct FuelTabView: View {
    var viewModel: AppViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                
                Spacer()
                
                Text("Fuel Management")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 20)
                
                HStack(spacing: 20) {
                    
                    // BOTÃO 1: LISTA DE LOGS
                    NavigationLink(destination: FuelCarListView(viewModel: viewModel)) {
                        MenuButtonCard(
                            title: "Fuel Logs",
                            subtitle: "Add & View",
                            icon: "fuelpump.fill",
                            color: .blue
                        )
                    }
                    
                    // BOTÃO 2: ESTATÍSTICAS (CORRIGIDO AQUI)
                    // Agora aponta para o novo FuelGeneralStatsView
                    NavigationLink(destination: FuelGeneralStatsView(viewModel: viewModel)) {
                        MenuButtonCard(
                            title: "Statistics",
                            subtitle: "Charts & Data",
                            icon: "chart.bar.xaxis",
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                Spacer()
            }
            .navigationTitle("Fuel")
            .navigationBarHidden(true)
            .background(Color.black)
        }
    }
}

// Componente Visual dos Botões (Mantém-se igual)
struct MenuButtonCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 15) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundStyle(color)
                )
            
            VStack(spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
    }
}
