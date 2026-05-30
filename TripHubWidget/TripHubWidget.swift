//
//  TripHubWidget.swift
//  TripHubWidget
//
//  Created by Andito Rizkyka Rianto on 29/05/26.
//

import WidgetKit
import SwiftUI

// ============================================================
// MARK: - Timeline Provider
// ============================================================

struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> TripWidgetEntry {
        TripWidgetEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TripWidgetEntry) -> ()) {
        let entry = currentEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = currentEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    /// Build an entry from the shared UserDefaults data
    private func currentEntry() -> TripWidgetEntry {
        if let data = WidgetDataManager.load() {
            return TripWidgetEntry(
                date: Date(),
                tripName: data.tripName,
                dateDescription: data.dateDescription,
                ticketCount: data.ticketCount,
                identityCount: data.identityCount,
                othersCount: data.othersCount,
                recentDocumentNames: data.recentDocumentNames,
                hasTrip: true
            )
        } else {
            return TripWidgetEntry.empty
        }
    }
}

// ============================================================
// MARK: - Timeline Entry
// ============================================================

struct TripWidgetEntry: TimelineEntry {
    let date: Date
    let tripName: String
    let dateDescription: String
    let ticketCount: Int
    let identityCount: Int
    let othersCount: Int
    let recentDocumentNames: [String]
    let hasTrip: Bool
    
    static let placeholder = TripWidgetEntry(
        date: Date(),
        tripName: "Bali Vacation",
        dateDescription: "5 Days trip from 5 May 2026 to 10 May 2026",
        ticketCount: 10,
        identityCount: 10,
        othersCount: 20,
        recentDocumentNames: ["Boarding Pass", "Hotel Voucher", "Insurance", "Visa Copy", "Itinerary", "Passport Scan", "Travel Guide", "COVID Test", "E-Ticket"],
        hasTrip: true
    )
    
    static let empty = TripWidgetEntry(
        date: Date(),
        tripName: "No Trip",
        dateDescription: "Create a trip to see details",
        ticketCount: 0,
        identityCount: 0,
        othersCount: 0,
        recentDocumentNames: [],
        hasTrip: false
    )
}

// ============================================================
// MARK: - Deep Link URLs
// ============================================================

enum WidgetDeepLink {
    static let ticket = URL(string: "triphub://category/ticket")!
    static let identity = URL(string: "triphub://category/identity")!
    static let others = URL(string: "triphub://category/others")!
    static let home = URL(string: "triphub://home")!
}

// ============================================================
// MARK: - 2x2 Small Widget View
// ============================================================

struct SmallWidgetView: View {
    var entry: TripWidgetEntry
    
    var body: some View {
        GeometryReader { geo in
            // 1. Perkecil spacing antar button di sini (misal dari 6 jadi 4)
            let spacing: CGFloat = 5
            let cellSize = (min(geo.size.width, geo.size.height) - spacing) / 2
            
            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    // App Logo
                    Link(destination: WidgetDeepLink.home) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
                            
                            Image("SymbolIcon")
                                        .resizable() // Wajib ditambahkan agar gambar bisa diubah ukurannya
                                        .scaledToFit() // Menjaga proporsi gambar agar tidak gepeng
                                        .frame(width: cellSize * 1, height: cellSize * 0.4)
                        }
                        .frame(width: cellSize, height: cellSize)
                    }
                    
                    // Identity Card
                    Link(destination: WidgetDeepLink.identity) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                            
                            Image(systemName: "person.text.rectangle.fill")
                                .font(.system(size: cellSize * 0.38, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width: cellSize, height: cellSize)
                    }
                }
                
                HStack(spacing: spacing) {
                    // Ticket / Airplane
                    Link(destination: WidgetDeepLink.ticket) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                            
                            Image(systemName: "airplane")
                                .font(.system(size: cellSize * 0.38, weight: .medium))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(-45))
                        }
                        .frame(width: cellSize, height: cellSize)
                    }
                    
                    // Others / Documents
                    Link(destination: WidgetDeepLink.others) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                            
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: cellSize * 0.38, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width: cellSize, height: cellSize)
                    }
                }
            }
            // Memastikan VStack mengambil seluruh ruang GeometryReader
            .frame(width: geo.size.width, height: geo.size.height)
        }
        // 3. KUNCI UTAMA: Negatif padding untuk menabrak margin bawaan Apple
        // Semakin besar angka minusnya (-14, -16), akan semakin mepet ke pinggir layar
        .padding(-4)
    }
}
// ============================================================
// MARK: - 4x2 Medium Widget View
// ============================================================

struct MediumWidgetView: View {
    var entry: TripWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Top: Trip name + date + logo
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.tripName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(entry.dateDescription)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image("roundedIcon")
                            .resizable() // Wajib ditambahkan agar gambar bisa diubah ukurannya
                            .scaledToFit() // Menjaga proporsi gambar agar tidak gepeng
                            .frame(width: 45, height:45 )
//                                .padding(.top,-3)
            }
            
//            Spacer()
            
            // Bottom: Category buttons
            HStack(spacing: 8) {
                CategoryButton(
                    icon: "airplane",
                    label: "Ticket",
                    count: entry.ticketCount,
                    url: WidgetDeepLink.ticket,
                    rotateIcon: true
                )
                
                CategoryButton(
                    icon: "person.text.rectangle.fill",
                    label: "Identity",
                    count: entry.identityCount,
                    url: WidgetDeepLink.identity
                )
                
                CategoryButton(
                    icon: "doc.on.doc.fill",
                    label: "Others",
                    count: entry.othersCount,
                    url: WidgetDeepLink.others
                )
            }
        }
        .padding(-1)
    }
}

// ============================================================
// MARK: - 4x4 Large Widget View
// ============================================================

struct LargeWidgetView: View {
    var entry: TripWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, ) {
            VStack(alignment: .leading, spacing: 20) {
                // Top: Trip name + date + logo
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.tripName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(entry.dateDescription)
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image("roundedIcon")
                                .resizable() // Wajib ditambahkan agar gambar bisa diubah ukurannya
                                .scaledToFit() // Menjaga proporsi gambar agar tidak gepeng
                                .frame(width: 45, height:45 )
//                                .padding(.top,-3)
                }
                
    //            Spacer()
                
                // Bottom: Category buttons
                HStack(spacing: 8) {
                    CategoryButton(
                        icon: "airplane",
                        label: "Ticket",
                        count: entry.ticketCount,
                        url: WidgetDeepLink.ticket,
                        rotateIcon: true
                    )
                    
                    CategoryButton(
                        icon: "person.text.rectangle.fill",
                        label: "Identity",
                        count: entry.identityCount,
                        url: WidgetDeepLink.identity
                    )
                    
                    CategoryButton(
                        icon: "doc.on.doc.fill",
                        label: "Others",
                        count: entry.othersCount,
                        url: WidgetDeepLink.others
                    )
                }
            }
            .padding(0)
            .padding(.top,5)
            Spacer()
            // Document list grid (max 9 items)
            let docs = Array(entry.recentDocumentNames.prefix(8))
            
            if docs.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 20))
                            .foregroundColor(Color.white.opacity(0.3))
                        Text("No documents yet")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                    Spacer()
                }
                Spacer()
            } else {
                // 3-column grid of documents
                VStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<2, id: \.self) { col in
                                let index = row * 3 + col
                                if index < docs.count {
                                    DocumentCell(name: docs[index])
                                } else {
                                    // Empty placeholder cell
                                    DocumentCell(name: "--")
                                        .opacity(0.4)
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
    }
}

// ============================================================
// MARK: - Reusable Components
// ============================================================

/// Category button used in medium and large widgets
struct CategoryButton: View {
    let icon: String
    let label: String
    let count: Int
    let url: URL
    var rotateIcon: Bool = false
    
    var body: some View {
        Link(destination: url) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(rotateIcon ? .degrees(-45) : .zero)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(count) Docs")
                        .font(.system(size: 9))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 3)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}

/// Single document cell in the 4x4 grid
struct DocumentCell: View {
    let name: String
    
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 20))
                .foregroundColor(Color.white.opacity(0.5))
            
            VStack(alignment:.leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white)
                    .lineLimit(1)
                Text(name)
                    .font(.system(size: 9))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 15)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

// ============================================================
// MARK: - Main Entry View (Size Switcher)
// ============================================================

struct TripHubWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// ============================================================
// MARK: - Widget Configuration
// ============================================================

struct TripHubWidget: Widget {
    let kind: String = "TripHubWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                TripHubWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(red: 0.11, green: 0.11, blue: 0.12)
                    }
            } else {
                TripHubWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color(red: 0.11, green: 0.11, blue: 0.12))
            }
        }
        .configurationDisplayName("TripHub")
        .description("View your trip details and documents at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// ============================================================
// MARK: - Previews
// ============================================================

#Preview("Small (2x2)", as: .systemSmall) {
    TripHubWidget()
} timeline: {
    TripWidgetEntry.placeholder
}

#Preview("Medium (4x2)", as: .systemMedium) {
    TripHubWidget()
} timeline: {
    TripWidgetEntry.placeholder
}

#Preview("Large (4x4)", as: .systemLarge) {
    TripHubWidget()
} timeline: {
    TripWidgetEntry.placeholder
}

#Preview("Empty State", as: .systemMedium) {
    TripHubWidget()
} timeline: {
    TripWidgetEntry.empty
}
