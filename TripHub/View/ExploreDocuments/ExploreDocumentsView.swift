//
//  ExploreDocumentsView.swift
//  TripHub
//

import SwiftUI
import SwiftData

// MARK: - ExploreDocumentsView

struct ExploreDocumentsView: View {

    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Query var allDocuments: [DocumentModel]

    // MARK: - Properties
    
    @State private var vm = ExploreDocumentsViewModel()
    @State private var selectedDocument: DocumentModel? = nil
    @State private var showQuickStore = false

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.categories, id: \.self) { category in
                            ChipItemView(
                                title: category,
                                isSelected: vm.selectedCategory == category
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    vm.selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                if vm.filteredDocuments(from: allDocuments).isEmpty {
                    VStack(spacing: 18) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.gray)
                        
                        VStack(spacing: 10) {
                            Text("No documents found")
                                .font(.helveticaCustom(size: 22, weight: .medium))
                                .foregroundStyle(.gray)
                            
                            Text("You haven't uploaded any documents\nthat match this filter.")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)

                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(vm.filteredDocuments(from: allDocuments)) { doc in
                            DocumentCardView(document: doc) {
                                selectedDocument = doc
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .sheet(item: $selectedDocument) { doc in
                DocumentPreviewView(document: doc)
            }
            .sheet(isPresented: $showQuickStore) {
                QuickStoreView()
            }
            .searchable(text: $vm.search, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showQuickStore = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
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
    ExploreDocumentsView()
        .modelContainer(for: [TripModel.self, DestinationModel.self, DocumentModel.self], inMemory: true)
}
