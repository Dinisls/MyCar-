import SwiftUI
import MapKit

struct TripDetailView: View {
    let trip: Trip
    var viewModel: AppViewModel
    
    // Cálculos de tempo
    var expectedTime: String {
        let avgSpeedKmh = (trip.distance / 1000) / (trip.duration / 3600)
        if avgSpeedKmh > 0 {
            let expectedDuration = (trip.distance / 1000) / max(avgSpeedKmh, 50) * 3600
            return formatDuration(expectedDuration)
        }
        return formatDuration(trip.duration)
    }
    
    var actualTime: String {
        formatDuration(trip.duration)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MAPA COM LINHAS COLORIDAS
                ZStack(alignment: .topLeading) {
                    TripMapView(trip: trip, viewModel: viewModel)
                        .frame(height: 350)
                        .cornerRadius(12)
                    
                    // Legenda de Velocidade
                    SpeedLegendView()
                        .padding(8)
                        .background(.thinMaterial)
                        .cornerRadius(8)
                        .padding(10)
                }
                
                // Cartões de Tempo
                HStack(spacing: 12) {
                    TimeCard(title: "Expected", time: expectedTime, icon: "arrow.forward.circle")
                    TimeCard(title: "Actual", time: actualTime, icon: "timer")
                }
                .padding(.horizontal)
                
                // Grelha de Estatísticas
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
                    
                    // Cálculo simples de tempo na "Red Zone" (>150km/h)
                    let redZoneMinutes = trip.points.filter { ($0.speed * 3.6) > 150 }.count
                    StatCard(
                        title: "Red Zone Time",
                        value: "\(redZoneMinutes)s",
                        icon: "bolt.fill",
                        color: .red
                    )
                }
                .padding(.horizontal)
                
                if let carName = trip.carName {
                    Text("Car: \(carName)")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .padding(.top)
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00:00"
    }
}

// MARK: - CUSTOM MAP COMPONENTS

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
        
        if let first = trip.points.first, let last = trip.points.last {
            let midLat = (first.latitude + last.latitude) / 2
            let midLon = (first.longitude + last.longitude) / 2
            let center = CLLocationCoordinate2D(latitude: midLat, longitude: midLon)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)
        
        guard trip.points.count > 1 else { return }
        
        var polylines: [ColoredPolyline] = []
        var mapRect = MKMapRect.null
        
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
        
        if let start = trip.points.first {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start.coordinate
            startAnnotation.title = "Start"
            uiView.addAnnotation(startAnnotation)
        }
        
        if let end = trip.points.last {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = end.coordinate
            endAnnotation.title = "End"
            uiView.addAnnotation(endAnnotation)
        }
        
        if !mapRect.isNull {
            uiView.setVisibleMapRect(mapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TripMapView
        
        init(_ parent: TripMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let coloredPolyline = overlay as? ColoredPolyline {
                let renderer = MKPolylineRenderer(polyline: coloredPolyline)
                renderer.strokeColor = coloredPolyline.color
                renderer.lineWidth = 4
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation.title == "Start" {
                let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "start")
                view.markerTintColor = .green
                view.glyphImage = UIImage(systemName: "flag.fill")
                return view
            } else if annotation.title == "End" {
                let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "end")
                view.markerTintColor = .red
                view.glyphImage = UIImage(systemName: "flag.checkered")
                return view
            }
            return nil
        }
    }
}

// MARK: - SUBVIEWS

struct SpeedLegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Speed Ranges")
                .font(.caption.bold())
                .foregroundStyle(.white)
            // CORREÇÃO: Usar TripLegendItem para evitar conflito com StatsView
            TripLegendItem(color: .green, text: "0 - 60 km/h")
            TripLegendItem(color: .blue, text: "61 - 90 km/h")
            TripLegendItem(color: .yellow, text: "91 - 120 km/h")
            TripLegendItem(color: .orange, text: "121 - 150 km/h")
            TripLegendItem(color: .red, text: "> 150 km/h")
        }
    }
}

// Mudei o nome para evitar conflito com StatsView
struct TripLegendItem: View {
    let color: Color
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(.caption2).foregroundStyle(.white)
        }
    }
}

struct TimeCard: View {
    let title: String
    let time: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text(time)
                .font(.title2.bold())
                .fontDesign(.monospaced)
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption)
            .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}
