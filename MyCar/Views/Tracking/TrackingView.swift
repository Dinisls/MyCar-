import SwiftUI
import MapKit

struct TrackingView: View {
    @Bindable var viewModel: AppViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            
            // 1. MAPA (Fundo)
            Map(position: .constant(.region(viewModel.locationManager.currentRegion))) {
                if !viewModel.locationManager.routePoints.isEmpty {
                    MapPolyline(coordinates: viewModel.locationManager.routePoints.map { $0.coordinate })
                        .stroke(currentSpeedColor, lineWidth: 5)
                }
                // Bolinha azul do utilizador
                UserAnnotation(coordinate: viewModel.locationManager.currentRegion.center)
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .ignoresSafeArea()
            
            // 2. PAINEL DE CONTROLO SUPERIOR (HUD)
            VStack(spacing: 0) {
                
                // --- LINHA 1: ESTATÍSTICAS (Velocidade, Tempo, Distância) ---
                HStack(alignment: .center, spacing: 15) {
                    
                    // Velocidade (Esquerda)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(viewModel.locationManager.currentSpeed * 3.6))")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(currentSpeedColor)
                            .contentTransition(.numericText())
                        
                        Text("km/h")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    
                    Spacer()
                    
                    // Separador Vertical
                    Rectangle().fill(.gray.opacity(0.3)).frame(width: 1, height: 30)
                    
                    Spacer()
                    
                    // Stats (Direita)
                    HStack(spacing: 20) {
                        // Tempo
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(formatDuration(viewModel.currentDuration))
                                .font(.headline.monospacedDigit())
                            Text("Time")
                                .font(.caption2).foregroundStyle(.gray)
                        }
                        
                        // Distância
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(String(format: "%.1f", viewModel.locationManager.totalDistance / 1000))
                                .font(.headline.monospacedDigit())
                            Text("km")
                                .font(.caption2).foregroundStyle(.gray)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                // --- DIVISÓRIA ---
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // --- LINHA 2: SELETOR DE CARRO (DROPDOWN) ---
                Menu {
                    // Opção para conduzir sem carro específico
                    Button {
                        viewModel.currentTripCar = nil
                    } label: {
                        Label("No specific car", systemImage: "car")
                    }
                    
                    // Lista dos carros da Garagem
                    ForEach(viewModel.myCars) { car in
                        Button {
                            viewModel.currentTripCar = car
                        } label: {
                            Label("\(car.make) \(car.model)", systemImage: "car.side.fill")
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if let car = viewModel.currentTripCar {
                            // Carro Selecionado
                            Image(systemName: "car.side.fill")
                                .foregroundStyle(.blue)
                            Text("\(car.make) \(car.model)")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        } else {
                            // Nenhum selecionado
                            Image(systemName: "car.fill")
                                .foregroundStyle(.gray)
                            Text("Select Vehicle")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle()) // Torna toda a área clicável
                }
            }
            .background(.thinMaterial) // Vidro fosco
            .clipShape(RoundedRectangle(cornerRadius: 20)) // Cantos arredondados
            .shadow(radius: 10)
            .padding(.horizontal, 20)
            .padding(.top, 10) // Margem do topo do ecrã
            
            
            // BARRA DE PROGRESSO FINA (Apenas visual, fora do painel)
            if viewModel.isTracking {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.3))
                        Capsule()
                            .fill(currentSpeedColor)
                            .frame(width: min(geo.size.width * (viewModel.locationManager.currentSpeed * 3.6 / 200.0), geo.size.width))
                            .animation(.linear, value: viewModel.locationManager.currentSpeed)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 40)
                .padding(.top, 5) // Ajustado para não bater no painel novo
            }
            
            Spacer()
            
            // 3. BOTÃO START/STOP (Fundo)
            VStack {
                Spacer() // Empurra para baixo
                Button(action: {
                    handleStartStop()
                }) {
                    HStack {
                        Image(systemName: viewModel.isTracking ? "stop.fill" : "play.fill")
                        Text(viewModel.isTracking ? "STOP" : "START")
                    }
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(viewModel.isTracking ? Color.red : Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: (viewModel.isTracking ? Color.red : Color.green).opacity(0.4), radius: 10, y: 5)
                }
                .padding(30)
                .padding(.bottom, 20)
            }
        }
    }
    
    // Lógica Simplificada (Já não precisa do popup)
    func handleStartStop() {
        withAnimation {
            if viewModel.isTracking {
                viewModel.stopTrip()
            } else {
                // Inicia a viagem com o carro que estiver selecionado no menu lá em cima
                viewModel.startTrip(with: viewModel.currentTripCar)
            }
        }
    }
    
    // Cor dinâmica
    var currentSpeedColor: Color {
        let speed = viewModel.locationManager.currentSpeed * 3.6
        if speed <= 60 { return .green }
        if speed <= 90 { return .blue }
        if speed <= 120 { return .yellow }
        if speed <= 150 { return .orange }
        return .red
    }
    
    func formatDuration(_ totalSeconds: TimeInterval) -> String {
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
