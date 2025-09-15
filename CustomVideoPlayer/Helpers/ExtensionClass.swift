//
//  ExtensionClass.swift
//  CustomVideoPlayer
//
//  Created by Sanskar IOS Dev on 15/09/25.
//

import Foundation
import SwiftUICore

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool,
                                          transform: (Self) -> Content,
                                          else elseTransform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            elseTransform(self)
        }
    }
}

func formatTime(seconds: Double) -> String {
    guard !seconds.isNaN && !seconds.isInfinite else { return "00:00" }
    let totalSeconds = Int(seconds)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let secs = totalSeconds % 60
    
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    } else {
        return String(format: "%02d:%02d", minutes, secs)
    }
}
