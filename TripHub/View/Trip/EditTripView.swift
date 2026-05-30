//
//  EditTripView.swift
//  TripHub
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - EditTripView

struct EditTripView: View {
    // MARK: - Properties
    
    @Bindable var trip: TripModel
    @State private var vm: TripEditViewModel

    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Init
    
    init(trip: TripModel) {
        self.trip = trip
        _vm = State(wrappedValue: TripEditViewModel(trip: trip))
    }

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    coverImageSection
                    tripNameSection
                    descriptionSection
                    documentsSection
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if vm.hasChanges {
                            vm.showDiscardConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.primary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        vm.showSaveConfirmation = true
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(vm.canSave ? Color.primaryGreen : .gray)
                    .disabled(!vm.canSave)
                }
            }
            .confirmationDialog(
                "Save Changes?",
                isPresented: $vm.showSaveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Save") {
                    vm.saveChanges(to: trip, context: modelContext)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Changes you made will be saved to \"\(trip.name)\".")
            }
            .alert(
                "Discard Changes?",
                isPresented: $vm.showDiscardConfirmation
            ) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("All unsaved changes will be lost.")
            }
            .interactiveDismissDisabled(vm.hasChanges)
        }
    }

    // MARK: - Sub-views

    private var coverImageSection: some View {
        EditCard(title: "Cover Image") {
            VStack(spacing: 12) {
                if let data = vm.coverImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primaryGreen.opacity(0.1))
                            .frame(height: 130)
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(.primaryGreen)
                            Text("No cover photo")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }

                PhotosPicker(selection: $vm.coverImagePickerItem, matching: .images) {
                    Label(
                        vm.coverImageData != nil ? "Change Photo" : "Choose Photo",
                        systemImage: "photo.badge.plus"
                    )
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.primaryGreen.opacity(0.1))
                    .cornerRadius(10)
                }
                .onChange(of: vm.coverImagePickerItem) { _, _ in
                    Task { await vm.loadSelectedPhoto() }
                }

                if vm.coverImageData != nil {
                    Button(role: .destructive) {
                        vm.coverImageData = nil
                        vm.coverImagePickerItem = nil
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }

    private var tripNameSection: some View {
        EditCard(title: "Trip Name") {
            VStack(alignment: .leading, spacing: 6) {
                Text("This name will appear on the main page.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Trip Name...", text: $vm.name)
                    .font(.body)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                if vm.name.trimmingCharacters(in: .whitespaces).isEmpty {
                    Label("Trip name cannot be empty.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    private var descriptionSection: some View {
        EditCard(title: "Description (Optional)") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tell us a little about this trip.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ZStack(alignment: .topLeading) {
                    if vm.tripDescription.isEmpty {
                        Text("Write description here...")
                            .foregroundColor(Color(.placeholderText))
                            .font(.body)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 9)
                    }
                    TextEditor(text: $vm.tripDescription)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                }
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
        }
    }

    @ViewBuilder
    private var documentsSection: some View {
        EditCard(title: "Documents") {
            VStack(alignment: .leading, spacing: 0) {
                if vm.editedDocuments.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text")
                            .foregroundColor(.gray)
                        Text("No documents in this trip.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(vm.editedDocuments) { editedDoc in
                        if !editedDoc.isMarkedForDeletion {
                            DocumentEditRow(editedDoc: editedDoc)
                            Divider().padding(.leading, 50)
                        }
                    }

                    let markedDocs = vm.editedDocuments.filter { $0.isMarkedForDeletion }
                    if !markedDocs.isEmpty {
                        Divider()
                        Text("Will be removed upon saving:")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 8)

                        ForEach(markedDocs) { editedDoc in
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 30)
                                    .padding(.trailing, 4)
                                Text(editedDoc.name)
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                Spacer()
                                Button("Cancel") {
                                    editedDoc.isMarkedForDeletion = false
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TripModel.self, configurations: config)
    let context = container.mainContext

    let trip = TripModel(
        name: "Bali Vacation",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
        tripDescription: "Fun vacation to Bali with family."
    )
    context.insert(trip)

    return EditTripView(trip: trip)
        .modelContainer(container)
}
