import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    var manager = PremiumManager.shared
    
    // O que fazer após sucesso (ex: iniciar viagem)
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
                // PLANO ANUAL (30€ / ano -> 2.50€ / mês)
                Button(action: {
                    manager.buyYearly()
                    dismiss()
                }) {
                    VStack(spacing: 4) {
                        Text("Plano Anual - 30,00 € / ano")
                            .bold()
                            .font(.headline)
                        
                        // TEXTO ALTERADO AQUI PARA DAR DESTAQUE
                        Text("Apenas 2,50 € / mês")
                            .font(.subheadline)
                            .fontWeight(.semibold) // Negrito suave para destacar
                            .foregroundStyle(.white) // Garante que brilha
                            
                        Text("(Poupe 37%)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                    // Adiciona uma borda dourada para destacar que é a "Melhor oferta"
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow, lineWidth: 2)
                    )
                }
                
                // PLANO MENSAL (3.99€)
                Button(action: {
                    manager.buyMonthly()
                    dismiss()
                }) {
                    Text("Plano Mensal - 3,99 € / mês")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Divider().padding(.vertical)
            
            // OPÇÃO DE ANÚNCIO
            Button(action: {
                isLoading = true
                manager.watchAd { success in
                    isLoading = false
                    if success {
                        onSuccess()
                        dismiss()
                    }
                }
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    HStack {
                        Image(systemName: "play.tv.fill")
                        Text("Ver Anúncio para Desbloquear")
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
