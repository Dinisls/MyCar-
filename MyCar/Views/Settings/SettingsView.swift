import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    var viewModel: AppViewModel
    @ObservedObject var premiumManager = PremiumManager.shared
    
    @State private var showResetAlert = false
    @State private var showPaywall = false
    
    // Feedback de restore compra
    @State private var isRestoring = false
    @State private var restoreAlertShowing = false
    
    // IMPORTAR (Restore Dados)
    @State private var isImporting = false
    @State private var importAlertMessage = ""
    @State private var showImportAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // --- SUBSCRIÇÃO ---
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
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.blue)
                        } else {
                            Button("Upgrade") { showPaywall = true }
                                .buttonStyle(.borderedProminent)
                                .font(.caption.bold())
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Button {
                        isRestoring = true
                        premiumManager.restorePurchases()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isRestoring = false
                            restoreAlertShowing = true
                        }
                    } label: {
                        if isRestoring { ProgressView() } else { Text("Restore Purchases").foregroundStyle(.blue) }
                    }
                    .disabled(isRestoring)
                }
                
                // --- BACKUP & RESTORE DE DADOS (NOVO SINGLE FILE) ---
                Section("Backup & Data") {
                    
                    // 1. EXPORTAR TUDO (1 Ficheiro)
                    // O ShareLink chama a função createUnifiedBackup que devolve o URL do ficheiro único
                    if let backupURL = viewModel.createUnifiedBackup() {
                        ShareLink(item: backupURL) {
                            Label("Export Full Backup", systemImage: "archivebox.circle.fill")
                        }
                    } else {
                        // Fallback se algo falhar
                        Text("Error creating backup").foregroundStyle(.red)
                    }
                    
                    // 2. IMPORTAR TUDO
                    Button {
                        isImporting = true
                    } label: {
                        Label("Import Backup File", systemImage: "arrow.down.doc.fill")
                    }
                    
                    // 3. APAGAR
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                    }
                }
                
                Section("About") {
                    HStack { Text("Version"); Spacer(); Text("1.0.1").foregroundStyle(.gray) }
                    Text("MyCar Project by DLS inc").font(.caption).foregroundStyle(.gray)
                }
            }
            .navigationTitle("Settings")
            
            // --- ALERTAS E SHEETS ---
            .alert("Reset Everything?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { viewModel.resetAllData() }
            } message: {
                Text("Irreversible action. All data will be lost.")
            }
            
            .alert("Import Status", isPresented: $showImportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importAlertMessage)
            }
            
            .alert("Restore Completed", isPresented: $restoreAlertShowing) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("We checked your Apple account for active subscriptions.")
            }
            
            .sheet(isPresented: $showPaywall) {
                PaywallView(onSuccess: { })
            }
            
            // --- FILE IMPORTER (Agora aceita 1 ficheiro JSON) ---
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false // Só 1 ficheiro
            ) { result in
                do {
                    // Segurança: Aceder ao ficheiro fora da Sandbox
                    let selectedUrl = try result.get().first!
                    guard selectedUrl.startAccessingSecurityScopedResource() else { return }
                    defer { selectedUrl.stopAccessingSecurityScopedResource() }
                    
                    // Tentar Restaurar
                    let success = viewModel.restoreUnifiedBackup(from: selectedUrl)
                    
                    if success {
                        importAlertMessage = "Backup loaded successfully!"
                    } else {
                        importAlertMessage = "Invalid backup file. Make sure you selected a MyCar_Backup.json file."
                    }
                    showImportAlert = true
                    
                } catch {
                    print("Erro ao importar: \(error)")
                    importAlertMessage = "Error reading file."
                    showImportAlert = true
                }
            }
        }
    }
    
    func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
