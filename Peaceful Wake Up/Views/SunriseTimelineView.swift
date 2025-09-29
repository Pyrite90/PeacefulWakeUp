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
    
    // Private state to prevent multiple alarm completions
    @State private var hasCompletedAlarm: Bool = false
    
    var body: some View {
        // Optimized TimelineView that updates sunrise effect every 10 seconds (reduced from 5 seconds)
        TimelineView(.periodic(from: Date(), by: 10.0)) { timeline in
            Color.clear
                .onAppear {
                    resetStateIfNeeded()
                    updateBrightnessForSunrise(currentTime: timeline.date)
                }
                .onChange(of: timeline.date) { _, newDate in
                    updateBrightnessForSunrise(currentTime: newDate)
                }
        }
    }
    
    private func resetStateIfNeeded() {
        // Reset completion flag when needed based on current state
        if !hasEnteredSunrisePhase {
            hasCompletedAlarm = false
        }
    }
    
    private func updateBrightnessForSunrise(currentTime: Date) {
        // Performance monitoring
        PerformanceMonitor.trackUpdate("SunriseUpdate")
        
        let sunriseStart = alarmTime.addingTimeInterval(-600) // 10 minutes before alarm
        
        // Safe execution with guard statements
        if currentTime >= sunriseStart && currentTime <= alarmTime {
            // Check if this is the first time entering sunrise phase
            if !hasEnteredSunrisePhase {
                // Mark that we've entered sunrise phase
                hasEnteredSunrisePhase = true
                
                // Safely capture the current system brightness before we change it
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
            
        } else if currentTime > alarmTime && hasEnteredSunrisePhase && !hasCompletedAlarm {
            // Alarm time reached - ensure full brightness and complete sunrise
            setBrightness(1.0)
            currentBrightness = 1.0
            
            // Mark alarm as completed to prevent multiple calls
            hasCompletedAlarm = true
            hasEnteredSunrisePhase = false
            onAlarmCompleted()
            
            print("🚨 Alarm completed - audio should now start playing")
        }
    }
}
