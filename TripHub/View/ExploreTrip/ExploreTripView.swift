//
//  ExploreTripView.swift
//  TripHub
//

import SwiftUI
import SwiftData

// MARK: - ExploreTripView

struct ExploreTripView: View {
    // MARK: - Environment
    
    @Query var allTrips: [TripModel]
    
    // MARK: - Properties
    
    @State private var vm = ExploreTripViewModel()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(vm.categories, id: \.self) { category in
                            ChipItemView(
                                title: category,
                                isSelected: vm.selectedCategory == category
                            )
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    vm.selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                
                if vm.filteredTrips(from: allTrips).isEmpty {
                    VStack(spacing: 18) {
                        Image(systemName: "map")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.gray)
                        
                        VStack(spacing: 10) {
                            Text("No trips found")
                                .font(.helveticaCustom(size: 22, weight: .medium))
                                .foregroundStyle(.gray)
                            
                            Text("You don't have any trips\nthat match this filter.")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    ForEach(vm.filteredTrips(from: allTrips)) { trip in
                        GlassmorphismCardView(trip: trip)
                            .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Your Trip")
            .searchable(text: $vm.search, placement: .navigationBarDrawer)
            .toolbar {
                ToolbarItem {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(hex: "#4AB855"))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    ExploreTripView()
}
