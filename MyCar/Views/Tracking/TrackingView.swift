import SwiftUI
import MapKit

struct TrackingView: View {
    @Bindable var viewModel: AppViewModel
    
    // Animação
    @State private var isPulsing = false
    
    // MAPA
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                
                // 1. O MAPA
                Map(position: $position) {
                    UserAnnotation()
                    if viewModel.isTracking && !viewModel.locationManager.routePoints.isEmpty {
                        MapPolyline(coordinates: viewModel.locationManager.routePoints.map(\.coordinate))
                            .stroke(.blue, lineWidth: 5)
                    }
                }
                .mapControls {
                    // Removemos o botão padrão para usar o nosso personalizado e visível
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea()
                
                // 2. BOTÃO DE RECENTRAR (Customizado e Flutuante)
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation {
                                position = .userLocation(fallback: .automatic)
                            }
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .padding(12)
                                .background(Color(uiColor: .systemBackground))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 60) // Espaço para não bater na Dynamic Island/Notch
                    }
                    Spacer()
                }
                
                // 3. CONTROLOS INFERIORES
                VStack(spacing: 20) {
                    
                    // A: Estatísticas
                    if viewModel.isTracking {
                        HStack(spacing: 30) {
                            VStack {
                                Text("\(Int(viewModel.locationManager.currentSpeed * 3.6))")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundStyle(.blue)
                                Text("km/h")
                                    .font(.caption).foregroundStyle(.gray)
                            }
                            Divider().frame(height: 40)
                            VStack {
                                Text(formatDuration(viewModel.currentDuration))
                                    .font(.title2.bold()).fontDesign(.monospaced)
                                Text("Duration")
                                    .font(.caption).foregroundStyle(.gray)
                            }
                            Divider().frame(height: 40)
                            VStack {
                                Text(String(format: "%.1f", viewModel.locationManager.totalDistance / 1000))
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)
                                Text("km")
                                    .font(.caption).foregroundStyle(.gray)
                            }
                        }
                        .padding()
                        .background(.thickMaterial)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding(.horizontal)
                    }
                    
                    // B: Seletor de Carro (Só aparece se parado)
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
                                    Button("\(car.make) \(car.model)") { viewModel.currentTripCar = car }
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
                        // Info do Carro durante viagem
                        if let car = viewModel.currentTripCar {
                            HStack {
                                Image(systemName: "car.fill").foregroundStyle(.gray)
                                Text("\(car.make) \(car.model)")
                                    .font(.subheadline)
                            }
                            .padding(8)
                            .background(.thinMaterial)
                            .cornerRadius(8)
                        }
                    }
                    
                    // C: BOTÕES DE CONTROLO (PLAY / PAUSE / STOP)
                    HStack(spacing: 40) {
                        
                        if viewModel.isTracking {
                            // BOTÃO 1: PAUSAR / RESUMIR
                            Button(action: {
                                withAnimation { viewModel.togglePause() }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 60, height: 60)
                                        .shadow(radius: 5)
                                    
                                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                            }
                            
                            // BOTÃO 2: PARAR (STOP)
                            Button(action: {
                                withAnimation { viewModel.stopTrip() }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 80, height: 80)
                                        .shadow(radius: 5)
                                    
                                    Image(systemName: "square.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(.white)
                                }
                            }
                        } else {
                            // BOTÃO INICIAR (VERDE GRANDE)
                            Button(action: {
                                startTripAction()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 80, height: 80)
                                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                    
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
                                    
                                    Image(systemName: "play.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(.white)
                                }
                            }
                            .disabled(viewModel.myCars.isEmpty)
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Tracking")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        }
    }
    
    func startTripAction() {
        withAnimation(.spring()) {
            viewModel.startTrip(with: viewModel.currentTripCar)
            position = .userLocation(fallback: .automatic)
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
