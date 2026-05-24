//
//  ExploreDocumentsView.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 12/05/26.
//

import SwiftUI
import _PhotosUI_SwiftUI

struct ExploreDocumentsView: View {
    @State private var searchText: String = ""
    
    let categories = ["All", "Identity", "Ticket", "Image", "Documents"]
    @State private var selectedCategory = "All"
    
    let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
    ]
    
    let items = Array(1...12).map {
        "Folder \($0)"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ScrollView(.horizontal, showsIndicators: false) {
                    // 4. HStack untuk menjejerkan chip ke samping
                                HStack(spacing: 12) {
                                    ForEach(categories, id: \.self) { category in
                                        // Memanggil desain chip di bawah
                                        ChipItemView(
                                            title: category,
                                            isSelected: selectedCategory == category
                                        )
                                        .onTapGesture {
                                            // Mengubah status terpilih ketika diklik
                                            withAnimation(.spring()) {
                                                selectedCategory = category
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16) // Jarak awal dan akhir konten dengan layar
                                .padding(.vertical, 8)
                }
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(items, id: \.self) { item in
////                        NavigationLink(destination: Text(item)) {
////                            Image(systemName: "folder")
////                                .font(.largeTitle)
////                                .foregroundColor(.primary)
////                        }
//                        Image(systemName: "folder")
//                            .font(.largeTitle)
//                            .foregroundColor(.primary)
//                            .padding(30)
//                            .background(.green)
                        ZStack {
//                            Color.gray
                            VStack(spacing:7) {
                                ZStack {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 40, height: 70)
//                                .cornerRadius(20)
                                Text("Image.pdfsssss")
                                    .lineLimit(2)
                                    .font(.helveticaCustom(size: 13))
                                Text("10/20/2022")
                                    .lineLimit(2)
                                    .font(.helveticaCustom(size: 13))
                                    .foregroundStyle(.gray)
                            
                            }
                            
                        }
                        .frame(width: 100)
                        .cornerRadius(20)
                            
                    }
                }
                .padding(.top, 16)
            }
            .searchable(text: $searchText,placement: .navigationBarDrawer )
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        // Action
                    }) {
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

#Preview {
    ExploreDocumentsView()
}
