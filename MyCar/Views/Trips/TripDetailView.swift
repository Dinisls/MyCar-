import SwiftUI
import MapKit
import Charts

struct TripDetailView: View {
    let trip: Trip
    
    // Estado para as Tags (apenas visual por agora)
    @State private var tags: [String] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // --- 1. MAPA ---
                if !trip.points.isEmpty {
                    ZStack(alignment: .bottomLeading) {
                        MapInteractionView(points: trip.points)
                            .frame(height: 350)
                            .cornerRadius(0) // As fotos mostram o mapa a ocupar a largura toda
                        
                        // Legenda de Ranges (Overlay no fundo do mapa ou logo abaixo)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Speed Ranges")
                                .font(.caption).bold().foregroundStyle(.blue)
                            HStack { Circle().fill(.green).frame(width: 6); Text("0 - 60 km/h").font(.caption2).foregroundStyle(.gray) }
                            HStack { Circle().fill(.blue).frame(width: 6); Text("61 - 90 km/h").font(.caption2).foregroundStyle(.gray) }
                            HStack { Circle().fill(.yellow).frame(width: 6); Text("91 - 120 km/h").font(.caption2).foregroundStyle(.gray) }
                            HStack { Circle().fill(.orange).frame(width: 6); Text("121 - 150 km/h").font(.caption2).foregroundStyle(.gray) }
                            HStack { Circle().fill(.red).frame(width: 6); Text("> 150 km/h").font(.caption2).foregroundStyle(.gray) }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .padding()
                    }
                }
                
                VStack(spacing: 15) {
                    
                    // --- 2. COMPARAÇÃO DE TEMPO ---
                    HStack {
                        VStack {
                            Text(formatDuration(trip.duration * 0.9)) // Simulado "Expected"
                                .font(.title)
                                .monospacedDigit()
                            Text("Expected")
                                .font(.caption).foregroundStyle(.gray)
                        }
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                        
                        VStack {
                            Text(formatDuration(trip.duration))
                                .font(.title)
                                .monospacedDigit()
                            Text("Actual")
                                .font(.caption).foregroundStyle(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(16)
                    
                    // --- 3. GRELHA DE ESTATÍSTICAS (4 Cartões) ---
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        
                        // Distância
                        DashboardCard(
                            value: String(format: "%.2f km", trip.distance / 1000),
                            label: "Distance",
                            icon: "road.lanes",
                            iconColor: .blue
                        )
                        
                        // Velocidade Média
                        DashboardCard(
                            value: String(format: "%.0f km/h", trip.averageSpeedKmh),
                            label: "Avg Speed",
                            icon: "speedometer",
                            iconColor: .orange
                        )
                        
                        // Velocidade Máxima
                        DashboardCard(
                            value: String(format: "%.0f km/h", trip.maxSpeedKmh),
                            label: "Max Speed",
                            icon: "gauge.with.dots.needle.100percent",
                            iconColor: .red
                        )
                        
                        // Red Zone Time
                        DashboardCard(
                            value: "\(Int(trip.redZoneDuration))s",
                            label: "Red Zone Time\n> 150 km/h",
                            icon: "bolt.fill",
                            iconColor: .red
                        )
                    }
                    
                    // --- 4. GRÁFICO DE VELOCIDADE (SPEED OVER TIME) ---
                    VStack(alignment: .leading) {
                        Text("Speed Over Time")
                            .font(.headline)
                        
                        Chart {
                            ForEach(Array(trip.points.enumerated()), id: \.offset) { index, point in
                                LineMark(
                                    x: .value("Time", index), // Usando índice como tempo (segundos)
                                    y: .value("Speed", point.speed * 3.6)
                                )
                                .foregroundStyle(.blue)
                                .interpolationMethod(.catmullRom)
                                
                                AreaMark(
                                    x: .value("Time", index),
                                    y: .value("Speed", point.speed * 3.6)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.5), .blue.opacity(0.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        }
                        .chartYAxis { AxisMarks(position: .trailing) }
                        .chartXAxis { AxisMarks(values: .automatic) } // Simplificado
                        .frame(height: 200)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(16)
                    
                    // --- 5. TAGS ---
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Tags").font(.headline)
                            Spacer()
                            Button(action: {}) {
                                Label("Add Tag", systemImage: "plus.circle")
                            }
                        }
                        
                        if tags.isEmpty {
                            Text("No tags yet")
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(8)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(16)
                    
                }
                .padding()
            }
        }
        .background(Color.black)
        .navigationTitle("Trip History")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00:00"
    }
}

// Subview para os Cartões Pretos
struct DashboardCard: View {
    let value: String
    let label: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
            
            VStack(spacing: 5) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }
}

// Subview do Mapa (Atualizada para linha verde)
struct MapInteractionView: View {
    let points: [TripPoint]
    
    var body: some View {
        let coordinates = points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        
        Map {
            MapPolyline(coordinates: coordinates)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            
            if let start = coordinates.first {
                Annotation("Start", coordinate: start) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                        .background(Circle().fill(.white))
                }
            }
            
            if let end = coordinates.last {
                Annotation("End", coordinate: end) {
                    Image(systemName: "flag.circle.fill")
                        .font(.title)
                        .foregroundStyle(.red)
                        .background(Circle().fill(.white))
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .colorScheme(.dark) // Força o mapa escuro como na foto
    }
}
