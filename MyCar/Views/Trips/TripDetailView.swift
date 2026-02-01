import SwiftUI
import MapKit
import Charts // IMPORTANTE PARA OS GRÁFICOS

struct TripDetailView: View {
    let trip: Trip
    var viewModel: AppViewModel
    
    // Para a animação do gráfico
    @State private var animateChart = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 1. MAPA
                TripMapView(trip: trip, viewModel: viewModel)
                    .frame(height: 350)
                    .cornerRadius(12)
                    .overlay(
                        SpeedLegendView()
                            .padding(8)
                            .background(.thinMaterial)
                            .cornerRadius(8)
                            .padding(10),
                        alignment: .topLeading
                    )
                
                // 2. GRÁFICO DE VELOCIDADE (PERFIL) - NOVO
                // Este gráfico mostra a evolução da velocidade ao longo do tempo (como na maioria das apps)
                VStack(alignment: .leading) {
                    Text("Speed Profile")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if trip.points.count > 1 {
                        Chart {
                            ForEach(Array(trip.points.enumerated()), id: \.offset) { index, point in
                                // Usamos AreaMark para um visual mais "preenchido"
                                AreaMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("Speed", point.speed * 3.6) // Converter m/s para km/h
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.6), .blue.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom) // Suaviza a linha
                                
                                // Linha de contorno
                                LineMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("Speed", point.speed * 3.6)
                                )
                                .foregroundStyle(.blue)
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) // Menos etiquetas no eixo X
                        }
                        .frame(height: 200)
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                // 3. CARTÕES DE ESTATÍSTICAS
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    StatCard(
                        title: "Distance",
                        value: String(format: "%.2f km", trip.distance / 1000),
                        icon: "road.lanes",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Avg Speed",
                        value: String(format: "%.0f km/h", trip.avgSpeedKmh),
                        icon: "speedometer",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Max Speed",
                        value: String(format: "%.0f km/h", trip.maxSpeedKmh),
                        icon: "dial.high.fill",
                        color: .red
                    )
                    
                    let duration = formatDuration(trip.duration)
                    StatCard(
                        title: "Duration",
                        value: duration,
                        icon: "clock.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal)
                
                // 4. GRÁFICO DE DISTRIBUIÇÃO (DONUT)
                // Caso a "imagem" fosse o gráfico circular de zonas
                VStack(alignment: .leading, spacing: 15) {
                    Text("Speed Zones")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    let distData = viewModel.getTripSpeedDistribution(trip: trip)
                    let totalMinutes = distData.reduce(0) { $0 + $1.minutes }
                    
                    if totalMinutes > 0 {
                        HStack {
                            Chart(distData) { item in
                                SectorMark(
                                    angle: .value("Minutes", item.minutes),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .foregroundStyle(item.color)
                                .cornerRadius(4)
                            }
                            .frame(height: 200)
                            
                            // Legenda Lateral
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(distData) { item in
                                    if item.minutes > 0 {
                                        HStack {
                                            Circle().fill(item.color).frame(width: 8, height: 8)
                                            Text(String(format: "%.0f%%", (item.minutes/totalMinutes)*100))
                                                .font(.caption.bold())
                                            Text(item.range)
                                                .font(.caption2)
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                if let carName = trip.carName {
                    Text("Vehicle: \(carName)")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .padding(.top, 10)
                }
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0m"
    }
}

// MARK: - COMPONENTES (Mapa e Legendas)

class ColoredPolyline: MKPolyline {
    var color: UIColor = .blue
}

struct TripMapView: UIViewRepresentable {
    let trip: Trip
    var viewModel: AppViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isUserInteractionEnabled = true
        mapView.showsUserLocation = false // Apenas a rota
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)
        
        guard trip.points.count > 1 else { return }
        
        var polylines: [ColoredPolyline] = []
        var mapRect = MKMapRect.null
        
        // Desenhar segmentos coloridos
        for i in 0..<(trip.points.count - 1) {
            let p1 = trip.points[i]
            let p2 = trip.points[i+1]
            let coords = [p1.coordinate, p2.coordinate]
            
            let speedKmh = p1.speed * 3.6
            let swiftUIColor = viewModel.getColorForSpeed(kmh: speedKmh)
            let uiColor = UIColor(swiftUIColor)
            
            let polyline = ColoredPolyline(coordinates: coords, count: 2)
            polyline.color = uiColor
            polylines.append(polyline)
            
            mapRect = mapRect.union(polyline.boundingMapRect)
        }
        
        uiView.addOverlays(polylines)
        
        // Marcadores Início/Fim
        if let start = trip.points.first {
            let startAnn = MKPointAnnotation()
            startAnn.coordinate = start.coordinate
            startAnn.title = "Start"
            uiView.addAnnotation(startAnn)
        }
        if let end = trip.points.last {
            let endAnn = MKPointAnnotation()
            endAnn.coordinate = end.coordinate
            endAnn.title = "End"
            uiView.addAnnotation(endAnn)
        }
        
        // Zoom na rota
        if !mapRect.isNull {
            let edgePadding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
            uiView.setVisibleMapRect(mapRect, edgePadding: edgePadding, animated: false)
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TripMapView
        init(_ parent: TripMapView) { self.parent = parent }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? ColoredPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = polyline.color
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let id = annotation.title == "Start" ? "start" : "end"
            let color: UIColor = annotation.title == "Start" ? .green : .red
            let icon = annotation.title == "Start" ? "flag.fill" : "flag.checkered"
            
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.markerTintColor = color
            view.glyphImage = UIImage(systemName: icon)
            return view
        }
    }
}

struct SpeedLegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Speed").font(.caption2.bold()).foregroundStyle(.primary)
            TripLegendItem(color: .green, text: "0-60")
            TripLegendItem(color: .blue, text: "60-90")
            TripLegendItem(color: .yellow, text: "90-120")
            TripLegendItem(color: .orange, text: "120-150")
            TripLegendItem(color: .red, text: "150+")
        }
    }
}

struct TripLegendItem: View {
    let color: Color
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            VStack(alignment: .leading) {
                Text(value).font(.headline)
                Text(title).font(.caption).foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}
