//
//  AlarmManager.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/26/25.
//

import SwiftUI
import Foundation

// MARK: - Alarm State Management
class AlarmManager: ObservableObject, AlarmManaging {
    @Published var alarmTime: Date = Date().addingTimeInterval(3600)
    @Published var isAlarmSet: Bool = false
    @Published var showingAlarmSetter: Bool = false
    @Published var isSilentAlarm: Bool = false
    @Published var alarmStartTime: Date?
    @Published var hasEnteredSunrisePhase: Bool = false
    
    // Computed properties for better performance
    var buttonText: String {
        if isAlarmSet {
            return "Cancel Alarm"
        } else if showingAlarmSetter {
            return "Confirm Alarm"
        } else {
            return "Set Alarm"
        }
    }
    
    var buttonColor: Color {
        if isAlarmSet {
            return Color.red.opacity(0.8)
        } else if showingAlarmSetter {
            return Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.8)
        } else {
            return Color(red: 1.0, green: 0.8, blue: 0.4).opacity(0.8)
        }
    }
    
    // Alarm logic methods
    func setAlarm() {
        // Ensure seconds and microseconds are set to 0 for precise alarm timing
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alarmTime)
        
        if let normalizedTime = calendar.date(from: components) {
            // Check if the alarm time is in the past (earlier today)
            let now = Date()
            if normalizedTime < now {
                // If alarm time is in the past, schedule it for tomorrow
                if let tomorrowAlarmTime = calendar.date(byAdding: .day, value: 1, to: normalizedTime) {
                    alarmTime = tomorrowAlarmTime
                } else {
                    // Fallback: use the normalized time as-is if date calculation fails
                    alarmTime = normalizedTime
                }
            } else {
                // Alarm time is in the future today, use it as-is
                alarmTime = normalizedTime
            }
        }
        
        isAlarmSet = true
        showingAlarmSetter = false
        // alarmStartTime will be set when alarm actually starts playing
    }
    
    func cancelAlarm() {
        isAlarmSet = false
        showingAlarmSetter = false
        hasEnteredSunrisePhase = false
        alarmStartTime = nil
    }
    
    func timeUntilAlarm(currentTime: Date) -> String {
        guard isAlarmSet else { return "" }
        
        let timeInterval = alarmTime.timeIntervalSince(currentTime)
        
        // If alarm time has passed, show that it's active
        guard timeInterval > 0 else { return "Alarm Active" }
        
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            let hourText = hours == 1 ? "Hour" : "Hours"
            let minuteText = minutes == 1 ? "Minute" : "Minutes"
            return "\(hours) \(hourText), \(minutes) \(minuteText)"
        } else {
            let minuteText = minutes == 1 ? "Minute" : "Minutes"
            return "\(minutes) \(minuteText)"
        }
    }
}
