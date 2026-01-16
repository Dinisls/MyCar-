//
//  TripsTabView.swift
//  MyCar
//
//  Created by Dinis Santos on 16/01/2026.
//


import SwiftUI

struct TripsTabView: View {
    var viewModel: AppViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                
                Spacer()
                
                // Título
                Text("Trips & Insights")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 20)
                
                HStack(spacing: 20) {
                    
                    // BOTÃO 1: HISTÓRICO
                    NavigationLink(destination: HistoryView(viewModel: viewModel)) {
                        TripMenuButtonCard(
                            title: "Trip History",
                            subtitle: "View All Trips",
                            icon: "clock.arrow.circlepath",
                            color: .purple
                        )
                    }
                    
                    // BOTÃO 2: ESTATÍSTICAS
                    NavigationLink(destination: StatsView(viewModel: viewModel)) {
                        TripMenuButtonCard(
                            title: "Statistics",
                            subtitle: "Performance",
                            icon: "chart.bar.xaxis",
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                Spacer()
            }
            .navigationTitle("Trips")
            .navigationBarHidden(true)
            .background(Color.black)
        }
    }
}

// Componente visual do botão (reutilizado localmente para evitar erros)
struct TripMenuButtonCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 15) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundStyle(color)
                )
            
            VStack(spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
    }
}