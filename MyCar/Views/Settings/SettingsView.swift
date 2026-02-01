import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    var viewModel: AppViewModel
    
    @State private var showResetAlert = false
    
    // IMPORTAR (Restore Dados)
    @State private var isImporting = false
    @State private var importAlertMessage = ""
    @State private var showImportAlert = false
    
    var body: some View {
        NavigationStack {
            List {
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
}
