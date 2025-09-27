//
//  OptimizedTimelineView.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/25/25.
//

import SwiftUI

// MARK: - Optimized Timeline Schedules
struct OptimizedTimelineSchedules {
        // Pre-configured schedules for better performance
    static let timeUpdate = PeriodicTimelineSchedule(from: Date(), by: 1.0)
    
    // Optimized schedules for different update frequencies
    static let inactivityCheck = PeriodicTimelineSchedule(from: Date(), by: 5.0)
    
    // Less frequent updates for sunrise effect
    static let sunriseUpdate = PeriodicTimelineSchedule(from: Date(), by: 10.0)
    
    // Volume updates (less frequent)
    static let volumeUpdate = PeriodicTimelineSchedule(from: Date(), by: 10.0)
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