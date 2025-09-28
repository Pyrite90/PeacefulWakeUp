//
//  SunriseTimelineView.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/25/25.
//

import SwiftUI

struct SunriseTimelineView: View {
    let alarmTime: Date
    @Binding var hasEnteredSunrisePhase: Bool
    @Binding var systemBrightnessAtSunriseStart: CGFloat
    @Binding var currentBrightness: CGFloat
    let setBrightness: (CGFloat) -> Void
    let onAlarmCompleted: () -> Void
    
    var body: some View {
        // Optimized TimelineView that updates sunrise effect every 10 seconds (reduced from 5 seconds)
        TimelineView(.periodic(from: Date(), by: 10.0)) { timeline in
            Color.clear
                .onAppear {
                    updateBrightnessForSunrise(currentTime: timeline.date)
                }
                .onChange(of: timeline.date) { _, newDate in
                    updateBrightnessForSunrise(currentTime: newDate)
                }
        }
    }
    
    private func updateBrightnessForSunrise(currentTime: Date) {
        // Performance monitoring
        PerformanceMonitor.trackUpdate("SunriseUpdate")
        
        let sunriseStart = alarmTime.addingTimeInterval(-600) // 10 minutes before alarm
        
        // Safe execution with error handling
        AppErrorHandler.safeExecute({
            if currentTime >= sunriseStart && currentTime <= alarmTime {
                // Check if this is the first time entering sunrise phase
                if !hasEnteredSunrisePhase {
                    // Mark that we've entered sunrise phase
                    hasEnteredSunrisePhase = true
                    
                    // Capture the current system brightness before we change it
                    systemBrightnessAtSunriseStart = UIScreen.main.brightness
                    
                    // Set system brightness to maximum immediately
                    setBrightness(1.0)
                    
                    print("🌅 Sunrise phase started - system brightness set to maximum")
                }
                
                // Calculate sunrise progress (0.0 to 1.0)
                let progress = currentTime.timeIntervalSince(sunriseStart) / 600.0
                let targetBrightness = max(0.0, min(1.0, progress))
                
                // Update app brightness for visual overlay (this creates the gradual sunrise effect)
                currentBrightness = CGFloat(targetBrightness)
                
            } else if currentTime > alarmTime && hasEnteredSunrisePhase {
                // Alarm time reached - ensure full brightness and complete sunrise
                setBrightness(1.0)
                currentBrightness = 1.0
                
                // Only trigger alarm completion once by resetting the sunrise phase flag
                hasEnteredSunrisePhase = false
                onAlarmCompleted()
            }
        }, fallback: (), context: "SunriseUpdate")
    }
}
