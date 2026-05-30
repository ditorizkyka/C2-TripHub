//
//  AssignTripSheet.swift
//  TripHub
//

import SwiftUI
import SwiftData

// MARK: - AssignTripSheet

struct AssignTripSheet: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties
    
    private let fileData: Data
    private let isImage: Bool
    private let originalName: String

    @State private var vm = QuickStoreViewModel()

    // MARK: - Initializers
    
    init(capturedImage: UIImage) {
        self.fileData     = capturedImage.jpegData(compressionQuality: 0.8) ?? Data()
        self.isImage      = true
        self.originalName = "Captured_Photo"
    }

    init(fileData: Data, isImage: Bool, originalName: String) {
        self.fileData     = fileData
        self.isImage      = isImage
        self.originalName = originalName
    }

    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        FormCard(title: "Document Preview") {
                            VStack(alignment: .leading, spacing: 16) {
                                if isImage, let uiImage = UIImage(data: fileData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 220)
                                        .cornerRadius(12)
                                        .padding(.vertical, 8)
                                } else {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(.systemRed).opacity(0.12))
                                                .frame(width: 56, height: 72)
                                            Image(systemName: "doc.richtext.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(.red)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(originalName)
                                                .font(.system(size: 15, weight: .semibold))
                                                .lineLimit(2)
                                            Text("PDF Document")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(fileSizeLabel)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }

                                if !vm.pendingDocuments.isEmpty {
                                    Divider()
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Document Details")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.accentColor)

                                        ForEach($vm.pendingDocuments) { $doc in
                                            QuickStoreView.SwipeablePendingDocRow(
                                                document: $doc,
                                                onDelete: { dismiss() }
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        TripFieldStoreData(vm: vm)

                        DestinationFieldStoreData(vm: vm)

                        Button {
                            vm.saveTrip(modelContext: modelContext)
                            dismiss()
                        } label: {
                            HStack {
                                if vm.isSaving {
                                    ProgressView().tint(.white)
                                    Text("Saving...")
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Document")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(vm.canSave ? Color(hex: "#4AB855") : Color(.systemGray4))
                            .cornerRadius(14)
                            .padding(.horizontal)
                        }
                        .disabled(!vm.canSave || vm.isSaving)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("Assign Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                populatePendingDocuments()
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Methods
    
    private var fileSizeLabel: String {
        let mb = Double(fileData.count) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }

    private func populatePendingDocuments() {
        guard vm.pendingDocuments.isEmpty else { return }
        let newDoc = PendingDocument(
            isImage:   isImage,
            imageData: isImage  ? fileData : nil,
            pdfData:   !isImage ? fileData : nil,
            name:      originalName
        )
        vm.pendingDocuments.append(newDoc)
    }
}
