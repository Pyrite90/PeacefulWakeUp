//
//  VolumeTimelineView.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/25/25.
//

import SwiftUI

struct VolumeTimelineView: View {
    let alarmStartTime: Date
    let setSystemVolume: (Float) -> Void
    
    var body: some View {
        // TimelineView that increases volume every 10 seconds
        TimelineView(.periodic(from: Date(), by: 10.0)) { timeline in
            Color.clear
                .onAppear {
                    increaseVolume(currentTime: timeline.date)
                }
                .onChange(of: timeline.date) { _, newDate in
                    increaseVolume(currentTime: newDate)
                }
        }
    }
    
    private func increaseVolume(currentTime: Date) {
        // Performance monitoring
        PerformanceMonitor.trackUpdate("VolumeUpdate")
        
        let timeElapsed = currentTime.timeIntervalSince(alarmStartTime)
        
        // Safe execution with error handling
        AppErrorHandler.safeExecute({
            print("🔊 Volume increase: \(timeElapsed) seconds elapsed")
            
            // Stop increasing volume after 3 minutes (180 seconds)
            guard timeElapsed <= 180 else {
                print("🔇 Volume timer stopped after 3 minutes")
                return
            }
            
            // Calculate target volume: from 10% to 100% over 3 minutes
            // Every 10 seconds for 3 minutes = 18 intervals
            // Volume increase per interval = (100% - 10%) / 18 = 5% per interval
            let intervalsElapsed = timeElapsed / 10.0
            let targetVolume = min(1.0, 0.1 + (intervalsElapsed * 0.05)) // 10% + 5% per interval, max 100%
            
            print("📢 Setting volume to: \(Int(targetVolume * 100))%")
            setSystemVolume(Float(targetVolume))
        }, fallback: (), context: "VolumeUpdate")
    }
}
