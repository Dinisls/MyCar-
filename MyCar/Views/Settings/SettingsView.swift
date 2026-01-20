import SwiftUI

struct SettingsView: View {
    var viewModel: AppViewModel
    @ObservedObject var premiumManager = PremiumManager.shared
    
    @State private var showResetAlert = false
    @State private var showPaywall = false
    
    // Estado para mostrar feedback do restauro
    @State private var isRestoring = false
    @State private var restoreAlertShowing = false
    
    var body: some View {
        NavigationStack {
            List {
                // --- SECÇÃO DE SUBSCRIÇÃO ---
                Section(header: Text("Subscription Status")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(premiumManager.isPremium ? "Premium Active" : "Free Plan")
                                .font(.headline)
                                .foregroundStyle(premiumManager.isPremium ? .primary : .secondary)
                            
                            if premiumManager.isPremium {
                                Text("Valid until: \(formatDate(premiumManager.premiumExpiryDate))")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else {
                                Text("Upgrade for unlimited trips & fuel logs")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        if premiumManager.isPremium {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        } else {
                            Button("Upgrade") {
                                showPaywall = true
                            }
                            .buttonStyle(.borderedProminent)
                            .font(.caption.bold())
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // --- NOVO BOTÃO RESTORE ---
                    // Só mostramos se NÃO for premium (ou sempre, como preferires. A Apple prefere sempre visível ou acessível)
                    Button {
                        isRestoring = true
                        premiumManager.restorePurchases()
                        
                        // Simular um loading de 2s para dar feedback ao utilizador
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isRestoring = false
                            restoreAlertShowing = true
                        }
                    } label: {
                        if isRestoring {
                            HStack {
                                Text("Restoring...")
                                Spacer()
                                ProgressView()
                            }
                        } else {
                            Text("Restore Purchases")
                                .foregroundStyle(.blue)
                        }
                    }
                    .disabled(isRestoring)
                }
                
                // ... (RESTO DAS SECÇÕES IGUAIS: Data Management, About) ...
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
                        Text("1.0.1")
                            .foregroundStyle(.gray)
                    }
                    Text("MyCar Project by DLS inc")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .navigationTitle("Settings")
            
            // ALERTAS E SHEETS
            .alert("Reset Everything?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.resetAllData()
                }
            } message: {
                Text("This will delete all trips, cars, and fuel logs. This action cannot be undone.")
            }
            
            // Alerta do Restore
            .alert("Restore Completed", isPresented: $restoreAlertShowing) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("We checked your Apple account for active subscriptions.")
            }
            
            .sheet(isPresented: $showPaywall) {
                PaywallView(onSuccess: { })
            }
        }
    }
    
    func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
