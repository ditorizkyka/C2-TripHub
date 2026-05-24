//
//  QuickStoreViewModel.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 22/05/26.
//

import SwiftUI

@MainActor
@Observable
class QuickStoreViewModel {
    // Data Trip & Destinations
    var searchText: String = ""
    var selectedTrip: String? = nil
    var startDate = Date()
    var isRangeEnabled = false
    var durationDays = 1
    
    var destinationName: String = ""
    var destinations: [DestinationModel] = []
    var destinationStartDate = Date()
    var destinationEndDate = Date()
    var selectedDestinationId: UUID? = nil
}


