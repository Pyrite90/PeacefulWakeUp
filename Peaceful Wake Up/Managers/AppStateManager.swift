//
//  AppStateManager.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/25/25.
//

import Foundation
import SwiftUI

// MARK: - App State Persistence
@MainActor
class AppStateManager: ObservableObject {
    // Singleton pattern for better memory management
    static let shared = AppStateManager()
    
    // Persistent storage keys
    private enum Keys {
        static let lastAlarmTime = "lastAlarmTime"
        static let isSilentAlarm = "isSilentAlarm"
        static let originalBrightness = "originalBrightness"
    }
    
    private init() {
        // Load persisted state on initialization
        loadPersistedState()
    }
    
    // MARK: - State Persistence
    func saveAlarmState(alarmTime: Date, isSilent: Bool) {
        UserDefaults.standard.set(alarmTime, forKey: Keys.lastAlarmTime)
        UserDefaults.standard.set(isSilent, forKey: Keys.isSilentAlarm)
    }
    
    func loadPersistedState() -> (alarmTime: Date?, isSilent: Bool) {
        let alarmTime = UserDefaults.standard.object(forKey: Keys.lastAlarmTime) as? Date
        let isSilent = UserDefaults.standard.bool(forKey: Keys.isSilentAlarm)
        return (alarmTime, isSilent)
    }
    
    func saveBrightnessState(_ brightness: CGFloat) {
        UserDefaults.standard.set(Double(brightness), forKey: Keys.originalBrightness)
    }
    
    func loadBrightnessState() -> CGFloat? {
        let brightness = UserDefaults.standard.double(forKey: Keys.originalBrightness)
        return brightness > 0 ? CGFloat(brightness) : nil
    }
    
    func clearPersistedState() {
        UserDefaults.standard.removeObject(forKey: Keys.lastAlarmTime)
        UserDefaults.standard.removeObject(forKey: Keys.isSilentAlarm)
        UserDefaults.standard.removeObject(forKey: Keys.originalBrightness)
    }
}

// MARK: - Performance Optimizations
struct ViewOptimizations {
    // Reduce unnecessary view updates
    static func shouldUpdateTime(_ oldTime: Date, _ newTime: Date) -> Bool {
        // Only update if minutes have changed (reduces second-by-second updates)
        let calendar = Calendar.current
        let oldComponents = calendar.dateComponents([.hour, .minute], from: oldTime)
        let newComponents = calendar.dateComponents([.hour, .minute], from: newTime)
        return oldComponents != newComponents
    }
    
    // Debounce rapid user interactions
    static func debounceUserInteraction(lastInteraction: Date, threshold: TimeInterval = 1.0) -> Bool {
        return Date().timeIntervalSince(lastInteraction) > threshold
    }
}