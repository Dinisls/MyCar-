import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    var viewModel: AppViewModel
    @ObservedObject var premiumManager = PremiumManager.shared
    
    @State private var showResetAlert = false
    @State private var showPaywall = false
    
    // Feedback de restore
    @State private var isRestoring = false
    @State private var restoreAlertShowing = false
    
    // IMPORTAR (Restore)
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
                
                // --- BACKUP & RESTORE DE DADOS ---
                Section("Backup & Data") {
                    // 1. EXPORTAR (VERSÃO MODERNA - iOS 16+)
                    // Isto resolve o problema do ecrã preto
                    ShareLink(items: getExportURLs()) {
                        Label("Export Data (Backup)", systemImage: "square.and.arrow.up")
                    }
                    // Desativa o botão se não houver ficheiros para exportar
                    .disabled(getExportURLs().isEmpty)
                    
                    // 2. IMPORTAR
                    Button {
                        isImporting = true
                    } label: {
                        Label("Import Data (Restore)", systemImage: "square.and.arrow.down")
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
            
            // --- FILE IMPORTER (O Seletor de Ficheiros) ---
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json], // Só aceita JSON
                allowsMultipleSelection: true // Podes selecionar Carros e Viagens ao mesmo tempo
            ) { result in
                do {
                    let selectedUrls = try result.get()
                    importFiles(urls: selectedUrls)
                } catch {
                    print("Erro ao importar: \(error)")
                }
            }
        }
    }
    
    // MARK: - LÓGICA DE IMPORTAÇÃO
    func importFiles(urls: [URL]) {
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var importCount = 0
        
        for url in urls {
            // 1. Pedir permissão de segurança para ler o ficheiro fora da app
            guard url.startAccessingSecurityScopedResource() else { continue }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            // 2. Definir o destino (substituir o ficheiro existente)
            let fileName = url.lastPathComponent
            let destinationURL = docsURL.appendingPathComponent(fileName)
            
            // Só importamos se tiver o nome correto para evitar corrupção
            if fileName == "trips_v1.json" || fileName == "my_cars_v1.json" {
                do {
                    // Remove o antigo se existir
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    // Copia o novo
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    importCount += 1
                } catch {
                    print("❌ Falha ao copiar \(fileName): \(error)")
                }
            } else {
                print("⚠️ Ficheiro ignorado (nome incorreto): \(fileName)")
            }
        }
        
        if importCount > 0 {
            // 3. Atualizar a App
            viewModel.reloadData()
            importAlertMessage = "Success! \(importCount) files imported."
            showImportAlert = true
        } else {
            importAlertMessage = "No valid backup files found. Make sure filenames are 'trips_v1.json' or 'my_cars_v1.json'."
            showImportAlert = true
        }
    }
    
    // MARK: - HELPER EXPORTAR (Devolve URLs para o ShareLink)
    func getExportURLs() -> [URL] {
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let tripsUrl = docsURL.appendingPathComponent("trips_v1.json")
        let carsUrl = docsURL.appendingPathComponent("my_cars_v1.json")
        
        var items: [URL] = []
        if FileManager.default.fileExists(atPath: tripsUrl.path) { items.append(tripsUrl) }
        if FileManager.default.fileExists(atPath: carsUrl.path) { items.append(carsUrl) }
        
        return items
    }
    
    func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
