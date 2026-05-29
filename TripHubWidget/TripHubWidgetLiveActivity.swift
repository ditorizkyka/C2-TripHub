//
//  TripHubWidgetLiveActivity.swift
//  TripHubWidget
//
//  Created by Andito Rizkyka Rianto on 29/05/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TripHubWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TripHubWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripHubWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TripHubWidgetAttributes {
    fileprivate static var preview: TripHubWidgetAttributes {
        TripHubWidgetAttributes(name: "World")
    }
}

extension TripHubWidgetAttributes.ContentState {
    fileprivate static var smiley: TripHubWidgetAttributes.ContentState {
        TripHubWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TripHubWidgetAttributes.ContentState {
         TripHubWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TripHubWidgetAttributes.preview) {
   TripHubWidgetLiveActivity()
} contentStates: {
    TripHubWidgetAttributes.ContentState.smiley
    TripHubWidgetAttributes.ContentState.starEyes
}
