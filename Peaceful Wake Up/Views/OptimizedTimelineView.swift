//
//  OptimizedTimelineView.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/25/25.
//

import SwiftUI

// MARK: - Optimized Timeline Schedules
struct OptimizedTimelineSchedules {
    // High frequency for time display (every second)
    static let timeUpdate = TimelineSchedule.periodic(from: Date(), by: 1.0)
    
    // Medium frequency for inactivity checking (every 5 seconds to reduce CPU usage)
    static let inactivityCheck = TimelineSchedule.periodic(from: Date(), by: 5.0)
    
    // Low frequency for sunrise updates (every 10 seconds during sunrise phase)
    static let sunriseUpdate = TimelineSchedule.periodic(from: Date(), by: 10.0)
    
    // Volume updates every 10 seconds (unchanged)
    static let volumeUpdate = TimelineSchedule.periodic(from: Date(), by: 10.0)
}

// MARK: - Performance Monitoring
struct PerformanceMonitor {
    private static var lastUpdateTimes: [String: Date] = [:]
    
    static func trackUpdate(_ identifier: String) {
        let now = Date()
        if let lastTime = lastUpdateTimes[identifier] {
            let interval = now.timeIntervalSince(lastTime)
            if interval < 0.5 { // Warn if updates are too frequent
                print("⚠️ Frequent updates detected for \(identifier): \(interval)s")
            }
        }
        lastUpdateTimes[identifier] = now
    }
    
    static func reset() {
        lastUpdateTimes.removeAll()
    }
}