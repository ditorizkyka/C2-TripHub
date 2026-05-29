//
//  TripHubWidgetBundle.swift
//  TripHubWidget
//
//  Created by Andito Rizkyka Rianto on 29/05/26.
//

import WidgetKit
import SwiftUI

@main
struct TripHubWidgetBundle: WidgetBundle {
    var body: some Widget {
        TripHubWidget()
        TripHubWidgetControl()
        TripHubWidgetLiveActivity()
    }
}
