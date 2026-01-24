import SwiftUI
import StoreKit
import GoogleMobileAds
import Combine

// Alias para facilitar (evita conflitos de nomes)
typealias Transaction = StoreKit.Transaction
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

class PremiumManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = PremiumManager()
    
    // --- ESTADO ---
    @Published var isPremium: Bool {
        didSet { UserDefaults.standard.set(isPremium, forKey: "isPremium") }
    }
    
    @Published var premiumExpiryDate: Double {
        didSet { UserDefaults.standard.set(premiumExpiryDate, forKey: "premiumExpiryDate") }
    }
    
    @Published var totalTripsStarted: Int {
        didSet { UserDefaults.standard.set(totalTripsStarted, forKey: "totalTripsStarted") }
    }
    
    @Published var totalFuelLogsAdded: Int {
        didSet { UserDefaults.standard.set(totalFuelLogsAdded, forKey: "totalFuelLogsAdded") }
    }
    
    let freeTripLimit = 2
    let freeFuelLimit = 2
    
    // --- ADMOB REAL (Substitui pelo teu ID com a barra /) ---
    private var rewardedAd: RewardedAd?
    // ⚠️ ID REAL DE PRODUÇÃO:
    let adUnitID = "ca-app-pub-1896559201156560/8251831356"
    
    // --- STOREKIT PRODUTOS ---
    // ⚠️ Estes IDs têm de ser IGUAIS aos que criaste no App Store Connect (Fase 1, Passo 3)
    let productIds = ["com.ds99.mycar.monthly", "com.ds99.mycar.yearly"]
    @Published var products: [Product] = []
    var updates: Task<Void, Never>? = nil

    override init() {
        self.isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        self.premiumExpiryDate = UserDefaults.standard.double(forKey: "premiumExpiryDate")
        self.totalTripsStarted = UserDefaults.standard.integer(forKey: "totalTripsStarted")
        self.totalFuelLogsAdded = UserDefaults.standard.integer(forKey: "totalFuelLogsAdded")
        
        super.init()
        
        // 1. Carregar Anúncio
        loadAd()
        
        // 2. Iniciar escuta de transações StoreKit (Pagamentos fora da app, renovações, etc)
        updates = Task {
            for await verification in Transaction.updates {
                if let transaction = try? verification.payloadValue {
                    await handle(transaction)
                    await transaction.finish()
                }
            }
        }
        
        // 3. Carregar Produtos da Apple
        Task {
            await requestProducts()
            // Verificar se já tem subscrição ativa ao iniciar
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    // MARK: - LIMITES
    func canStartTrip() -> Bool {
        if isPremium { return true }
        return totalTripsStarted < freeTripLimit
    }
    
    func canAddFuelLog() -> Bool {
        if isPremium { return true }
        return totalFuelLogsAdded < freeFuelLimit
    }
    
    func incrementTripCount() { totalTripsStarted += 1 }
    func incrementFuelLogCount() { totalFuelLogsAdded += 1 }

    // MARK: - ADMOB (ANÚNCIOS)
    func loadAd() {
        let request = Request()
        RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("❌ Erro AdMob: \(error.localizedDescription)")
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
        }
    }
    
    func watchAd(completion: @escaping (Bool) -> Void) {
        guard let ad = rewardedAd else {
            loadAd()
            completion(false)
            return
        }
        guard let root = getRootViewController() else {
            completion(false)
            return
        }
        ad.present(from: root) {
            completion(true) // Recompensa
        }
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        self.rewardedAd = nil
        loadAd()
    }

    // MARK: - STOREKIT (PAGAMENTOS REAIS)
    
    @MainActor
    func requestProducts() async {
        do {
            products = try await Product.products(for: productIds)
        } catch {
            print("❌ Falha ao carregar produtos: \(error)")
        }
    }
    
    func buyMonthly() {
        // ID do Mensal
        guard let product = products.first(where: { $0.id == "com.ds99.mycar.monthly" }) else { return }
        purchase(product)
    }
    
    func buyYearly() {
        // --- MODO DE TESTE (Bypass Pagamento) ---
        // Isto simula uma compra bem sucedida instantaneamente
        print("🔓 MODO DE TESTE: A ativar Premium gratuitamente...")
        self.isPremium = true
        
        // --- CÓDIGO ORIGINAL (Comentado para testes) ---
        /*
        guard let product = products.first(where: { $0.id == "com.ds99.mycar.yearly" }) else { return }
        purchase(product)
        */
    }
    
    func purchase(_ product: Product) {
        Task {
            do {
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    if let transaction = try? verification.payloadValue {
                        await handle(transaction)
                        await transaction.finish()
                        print("✅ Compra com sucesso!")
                    }
                case .userCancelled:
                    print("Cancelado pelo utilizador")
                default:
                    break
                }
            } catch {
                print("❌ Erro na compra: \(error)")
            }
        }
    }
    
    func restorePurchases() {
        Task {
            try? await AppStore.sync()
            await updateSubscriptionStatus()
        }
    }
    
    // MARK: - LÓGICA DE VALIDAÇÃO (StoreKit 2)
    
    @MainActor
    private func handle(_ transaction: Transaction) async {
        // Verifica se a transação é válida e desbloqueia o conteúdo
        if transaction.revocationDate == nil {
            self.isPremium = true
            if let expiry = transaction.expirationDate {
                self.premiumExpiryDate = expiry.timeIntervalSince1970
            }
        } else {
            self.isPremium = false
        }
    }
    
    @MainActor
    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                // Se encontrar qualquer subscrição válida e não expirada
                if transaction.revocationDate == nil {
                    hasActiveSubscription = true
                    if let expiry = transaction.expirationDate {
                        self.premiumExpiryDate = expiry.timeIntervalSince1970
                    }
                    // Atualiza a UI
                    self.isPremium = true
                }
            }
        }
        
        if !hasActiveSubscription {
            self.isPremium = false
        }
    }
    
    // Helper UI
    private func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return nil }
        return window.rootViewController
    }
}
