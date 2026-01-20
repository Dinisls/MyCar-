import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager = PremiumManager.shared
    
    // O que o utilizador quer fazer depois de desbloquear (ex: iniciar viagem)
    var onSuccess: () -> Void
    
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Cabeçalho
            Image(systemName: "crown.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
                .padding(.top, 40)
            
            Text("MyCar Premium")
                .font(.largeTitle.bold())
            
            Text("Atingiu o limite gratuito.")
                .font(.headline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(text: "Viagens ilimitadas")
                FeatureRow(text: "Registos de combustível ilimitados")
                FeatureRow(text: "Sem anúncios")
                FeatureRow(text: "Suporte ao desenvolvimento")
            }
            .padding()
            
            Spacer()
            
            // OPÇÕES DE COMPRA
            VStack(spacing: 12) {
                Button(action: {
                    manager.buyYearly()
                    dismiss()
                }) {
                    VStack {
                        Text("Plano Anual - 25,00 € / ano")
                            .bold()
                        Text("Poupe com o pagamento anual")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    manager.buyMonthly()
                    dismiss()
                }) {
                    Text("Plano Mensal - 2,99 € / mês")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Divider().padding(.vertical)
            
            // OPÇÃO DE ANÚNCIO (Uma vez)
            Button(action: {
                isLoading = true
                manager.watchAd { success in
                    isLoading = false
                    if success {
                        onSuccess() // Executa a ação (ex: inicia viagem)
                        dismiss()
                    }
                }
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    HStack {
                        Image(systemName: "play.tv.fill")
                        Text("Ver Anúncio (Uso Único)")
                    }
                    .foregroundStyle(.gray)
                    .font(.subheadline)
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(uiColor: .systemBackground))
    }
}

struct FeatureRow: View {
    let text: String
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text(text)
        }
    }
}