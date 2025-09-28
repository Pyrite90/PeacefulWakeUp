//
//  InactivityTimelineView.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/25/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct InactivityTimelineView: View {
    let lastInteraction: Date
    let isAlarmSet: Bool
    let alarmTime: Date
    @Binding var showBlackOverlay: Bool
    @Binding var currentBrightness: CGFloat
    @Binding var brightnessBeforeInactivity: CGFloat
    let setBrightness: (CGFloat) -> Void
    
    var body: some View {
        // Optimized TimelineView that checks inactivity every 5 seconds (reduced from 1 second)
        TimelineView(.periodic(from: Date(), by: 5.0)) { timeline in
            Color.clear
                .onAppear {
                    checkInactivity(currentTime: timeline.date)
                }
                .onChange(of: timeline.date) { _, newDate in
                    checkInactivity(currentTime: newDate)
                }
        }
    }
    
    private func checkInactivity(currentTime: Date) {
        // Performance monitoring
        PerformanceMonitor.trackUpdate("InactivityCheck")
        
        let timeSinceLastInteraction = currentTime.timeIntervalSince(lastInteraction)
        let sunriseStart = alarmTime.addingTimeInterval(-600) // 10 minutes before alarm
        
        // If alarm is set and we're within 10 minutes of alarm time, keep overlay off
        let shouldKeepOverlayOff = isAlarmSet && currentTime >= sunriseStart
        
        // Increased threshold to 35 seconds to account for 5-second check intervals
        let shouldShowOverlay = !shouldKeepOverlayOff && timeSinceLastInteraction > 35

        if shouldShowOverlay != showBlackOverlay {
            // Safe execution with error handling
            AppErrorHandler.safeExecute({
                if shouldShowOverlay {
                    // About to show black overlay - save current brightness and set to minimum
                    #if os(iOS)
                    if iOSCompatibility.isiOS26OrLater {
                        brightnessBeforeInactivity = 1.0
                    } else {
                        brightnessBeforeInactivity = UIScreen.main.brightness
                    }
                    #endif
                    setBrightness(0.01)
                    currentBrightness = 0.01
                }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    showBlackOverlay = shouldShowOverlay
                }
            }, fallback: (), context: "InactivityCheck")
        }
    }
}
