//
//  Logger.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/26/25.
//

import Foundation
import os.log

// MARK: - Logging Framework
struct AppLogger {
    enum LogLevel: String, CaseIterable {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING" 
        case error = "🚨 ERROR"
        case performance = "📊 PERF"
    }
    
    enum Category: String, CaseIterable {
        case audio = "Audio"
        case brightness = "Brightness"
        case alarm = "Alarm"
        case ui = "UI"
        case background = "Background"
        case performance = "Performance"
        case system = "System"
    }
    
    private static let subsystem = "com.mikemcdonald.PeacefulWakeUp"
    
    // OS Log instances for different categories
    private static let audioLog = OSLog(subsystem: subsystem, category: Category.audio.rawValue)
    private static let brightnessLog = OSLog(subsystem: subsystem, category: Category.brightness.rawValue)
    private static let alarmLog = OSLog(subsystem: subsystem, category: Category.alarm.rawValue)
    private static let uiLog = OSLog(subsystem: subsystem, category: Category.ui.rawValue)
    private static let backgroundLog = OSLog(subsystem: subsystem, category: Category.background.rawValue)
    private static let performanceLog = OSLog(subsystem: subsystem, category: Category.performance.rawValue)
    private static let systemLog = OSLog(subsystem: subsystem, category: Category.system.rawValue)
    
    // MARK: - Logging Methods
    static func debug(_ message: String, category: Category = .system, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, category: Category = .system, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, category: Category = .system, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, category: Category = .system, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    static func performance(_ message: String, duration: TimeInterval? = nil, category: Category = .performance, file: String = #file, function: String = #function, line: Int = #line) {
        let durationStr = duration.map { String(format: " (%.3fs)", $0) } ?? ""
        log(message + durationStr, level: .performance, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Core Logging Implementation
    private static func log(_ message: String, level: LogLevel, category: Category, file: String, function: String, line: Int) {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let formattedMessage = "\(level.rawValue) [\(category.rawValue)] \(filename):\(line) \(function) - \(message)"
        
        // Console logging for debug builds
        #if DEBUG
        if AppConfiguration.Debug.verboseLogging {
            print(formattedMessage)
        }
        #endif
        
        // OS Log for system integration
        let osLog = getOSLog(for: category)
        let osLogType = getOSLogType(for: level)
        
        os_log("%{public}@", log: osLog, type: osLogType, formattedMessage)
        
        // Could integrate with analytics/crash reporting here
        if AppConfiguration.ErrorHandling.errorReportingEnabled && level == .error {
            // Analytics.recordError(message, category: category.rawValue)
        }
    }
    
    private static func getOSLog(for category: Category) -> OSLog {
        switch category {
        case .audio: return audioLog
        case .brightness: return brightnessLog
        case .alarm: return alarmLog
        case .ui: return uiLog
        case .background: return backgroundLog
        case .performance: return performanceLog
        case .system: return systemLog
        }
    }
    
    private static func getOSLogType(for level: LogLevel) -> OSLogType {
        switch level {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .performance: return .info
        }
    }
}

// MARK: - Performance Measurement
struct PerformanceMeasurement {
    private let startTime: CFAbsoluteTime
    private let operation: String
    private let category: AppLogger.Category
    
    init(operation: String, category: AppLogger.Category = .performance) {
        self.operation = operation
        self.category = category
        self.startTime = CFAbsoluteTimeGetCurrent()
        
        AppLogger.debug("Started: \(operation)", category: category)
    }
    
    func end() -> TimeInterval {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        AppLogger.performance("Completed: \(operation)", duration: duration, category: category)
        return duration
    }
}

// MARK: - Convenience Extensions
extension AppLogger {
    // Audio logging helpers
    static func audioSetupStarted() {
        info("Audio session setup started", category: .audio)
    }
    
    static func audioSetupCompleted(duration: TimeInterval) {
        performance("Audio session setup completed", duration: duration, category: .audio)
    }
    
    static func audioPlaybackStarted() {
        info("Alarm audio playback started", category: .audio)
    }
    
    static func audioInterruption(reason: String) {
        warning("Audio interrupted: \(reason)", category: .audio)
    }
    
    // Brightness logging helpers
    static func brightnessChanged(from: CGFloat, to: CGFloat) {
        debug("Brightness changed from \(from) to \(to)", category: .brightness)
    }
    
    static func sunriseEffectStarted() {
        info("Sunrise effect started", category: .brightness)
    }
    
    // Alarm logging helpers
    static func alarmSet(time: Date) {
        info("Alarm set for \(time)", category: .alarm)
    }
    
    static func alarmTriggered() {
        info("Alarm triggered", category: .alarm)
    }
    
    static func alarmCancelled() {
        info("Alarm cancelled", category: .alarm)
    }
}
