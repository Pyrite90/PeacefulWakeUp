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
        isAlarmSet = true
        showingAlarmSetter = false
        alarmStartTime = Date()
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
            return "\(hours) Hours \(minutes) Minutes"
        } else {
            return "\(minutes) Minutes"
        }
    }
}
