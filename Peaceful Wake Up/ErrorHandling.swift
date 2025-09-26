//
//  ErrorHandling.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/25/25.
//

import Foundation
import SwiftUI

// MARK: - Error Handling and Recovery
struct AppErrorHandler {
    enum AlarmError: LocalizedError {
        case audioPlayerFailed
        case brightnessControlUnavailable
        case invalidAlarmTime
        case volumeControlFailed
        case backgroundTaskFailed
        case memoryWarning
        case audioInterruption(reason: String)
        
        var errorDescription: String? {
            switch self {
            case .audioPlayerFailed:
                return "Failed to initialize audio player"
            case .brightnessControlUnavailable:
                return "Brightness control is not available"
            case .invalidAlarmTime:
                return "Invalid alarm time selected"
            case .volumeControlFailed:
                return "Volume control failed"
            case .backgroundTaskFailed:
                return "Background task management failed"
            case .memoryWarning:
                return "Low memory warning - some features may be limited"
            case .audioInterruption(let reason):
                return "Audio interrupted: \(reason)"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .audioPlayerFailed:
                return "Check device volume and audio permissions"
            case .brightnessControlUnavailable:
                return "Brightness features will be disabled"
            case .invalidAlarmTime:
                return "Please select a valid time in the future"
            case .volumeControlFailed:
                return "Volume control may not work properly"
            case .backgroundTaskFailed:
                return "Alarm may not work reliably in background"
            case .memoryWarning:
                return "Close other apps to improve performance"
            case .audioInterruption:
                return "Audio will resume automatically when possible"
            }
        }
    }
    
    // MARK: - Error Recovery Strategies
    static func handleError(_ error: Error, context: String, recovery: (() -> Void)? = nil) {
        print("🚨 Error in \(context): \(error.localizedDescription)")
        
        // Log to system for debugging
        #if DEBUG
        print("Debug: \(error)")
        if let alarmError = error as? AlarmError {
            print("Recovery suggestion: \(alarmError.recoverySuggestion ?? "None")")
        }
        #endif
        
        // Execute recovery strategy if provided
        recovery?()
        
        // Could integrate with crash reporting here
        // Analytics.recordError(error, context: context)
    }
    
    static func safeExecute<T>(_ operation: () throws -> T, fallback: T, context: String, recovery: (() -> Void)? = nil) -> T {
        do {
            return try operation()
        } catch {
            handleError(error, context: context, recovery: recovery)
            return fallback
        }
    }
}

// MARK: - Memory Management
struct MemoryManager {
    static func cleanup() {
        // Force memory cleanup
        autoreleasepool {
            // This helps release temporary objects
        }
    }
    
    static func logMemoryUsage(_ identifier: String) {
        let memoryUsage = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryUsage) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryMB = Float(memoryUsage.resident_size) / 1024.0 / 1024.0
            print("📊 Memory usage (\(identifier)): \(String(format: "%.1f", memoryMB)) MB")
        }
    }
}