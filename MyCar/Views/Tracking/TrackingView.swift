import SwiftUI
import MapKit

struct TrackingView: View {
    @Bindable var viewModel: AppViewModel
    
    // Para animação do botão de Start
    @State private var isPulsing = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                
                // 1. O MAPA (Ecrã Inteiro)
                // ALTERAÇÃO: .ignoresSafeArea() sem argumentos faz o mapa ir até ao fundo do ecrã
                Map(coordinateRegion: $viewModel.locationManager.currentRegion, showsUserLocation: true, userTrackingMode: .constant(.follow))
                    .ignoresSafeArea()
                
                // 2. CONTROLOS FLUTUANTES
                VStack(spacing: 20) {
                    
                    // A: Estatísticas (Só aparecem se estiver a gravar)
                    if viewModel.isTracking {
                        HStack(spacing: 30) {
                            VStack {
                                Text("\(Int(viewModel.locationManager.currentSpeed * 3.6))")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundStyle(.blue)
                                Text("km/h")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            
                            Divider().frame(height: 40)
                            
                            VStack {
                                Text(formatDuration(viewModel.currentDuration))
                                    .font(.title2.bold())
                                    .fontDesign(.monospaced)
                                Text("Duration")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            
                            Divider().frame(height: 40)
                            
                            VStack {
                                Text(String(format: "%.1f", viewModel.locationManager.totalDistance / 1000))
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)
                                Text("km")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding()
                        .background(.thickMaterial)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding(.horizontal)
                    }
                    
                    // B: Seletor de Carro (Se não estiver a gravar)
                    if !viewModel.isTracking {
                        if viewModel.myCars.isEmpty {
                            Text("Add a car in Garage to start")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                                .padding(8)
                                .background(.thinMaterial)
                                .cornerRadius(8)
                        } else {
                            Menu {
                                ForEach(viewModel.myCars) { car in
                                    Button("\(car.make) \(car.model)") {
                                        viewModel.currentTripCar = car
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "car.fill")
                                    Text(viewModel.currentTripCar == nil ? "Select Car" : "\(viewModel.currentTripCar!.make) \(viewModel.currentTripCar!.model)")
                                    Image(systemName: "chevron.up")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(Color.blue)
                                .clipShape(Capsule())
                                .shadow(radius: 5)
                            }
                        }
                    } else {
                        // Durante a viagem
                        if let car = viewModel.currentTripCar {
                            HStack {
                                Image(systemName: "car.fill")
                                    .foregroundStyle(.gray)
                                Text("\(car.make) \(car.model)")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                            .padding(8)
                            .background(.thinMaterial)
                            .cornerRadius(8)
                        }
                    }
                    
                    // C: BOTÃO START / STOP
                    Button(action: {
                        withAnimation(.spring()) {
                            if viewModel.isTracking {
                                viewModel.stopTrip()
                            } else {
                                viewModel.startTrip(with: viewModel.currentTripCar)
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isTracking ? Color.red : Color.green)
                                .frame(width: 80, height: 80)
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            if !viewModel.isTracking {
                                Circle()
                                    .stroke(Color.green.opacity(0.5), lineWidth: 4)
                                    .frame(width: 90, height: 90)
                                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                                    .opacity(isPulsing ? 0 : 1)
                                    .onAppear {
                                        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                                            isPulsing = true
                                        }
                                    }
                            }
                            
                            Image(systemName: viewModel.isTracking ? "stop.fill" : "play.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(viewModel.myCars.isEmpty && !viewModel.isTracking)
                    // ALTERAÇÃO: Adicionei padding extra no fundo (60) para que os botões
                    // fiquem acima da Tab Bar (Menu) e não escondidos atrás dela.
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Tracking")
            // Mapa ignora topo e fundo (ecrã total)
            .toolbarBackground(.hidden, for: .navigationBar)
            
            // ALTERAÇÃO: Define a Tab Bar como visível mas com material translúcido
            // Isto permite ver o mapa desfocado por trás dos ícones de baixo
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
}
