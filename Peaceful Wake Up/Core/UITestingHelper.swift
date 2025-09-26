//
//  UITestingHelper.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/26/25.
//

import SwiftUI

// MARK: - UI Testing Support
struct UITestingHelper {
    // Accessibility identifiers for UI testing
    enum AccessibilityID: String, CaseIterable {
        case alarmTimeDisplay = "alarm-time-display"
        case setAlarmButton = "set-alarm-button"
        case cancelAlarmButton = "cancel-alarm-button"
        case stopAlarmButton = "stop-alarm-button"
        case timeUntilAlarmLabel = "time-until-alarm-label"
        case volumeSlider = "volume-slider"
        case volumeValueLabel = "volume-value-label"
        case brightnessSlider = "brightness-slider" 
        case brightnessValueLabel = "brightness-value-label"
        case alarmStatusIcon = "alarm-status-icon"
        case mainContainer = "main-container"
        case timePicker = "time-picker"
        
        // Testing-specific identifiers
        case testModeIndicator = "test-mode-indicator"
        case performanceMetrics = "performance-metrics"
        case errorDisplay = "error-display"
    }
    
    // MARK: - Testing State
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }
    
    static var isPerformanceTesting: Bool {
        ProcessInfo.processInfo.arguments.contains("PERFORMANCE_TESTING")
    }
    
    static var shouldSkipAnimations: Bool {
        isUITesting || ProcessInfo.processInfo.arguments.contains("DISABLE_ANIMATIONS")
    }
    
    // MARK: - Testing Modifiers
    static func accessibilityIdentifier(_ id: AccessibilityID) -> some ViewModifier {
        AccessibilityIdentifierModifier(id: id.rawValue)
    }
    
    static func testingLabel(_ label: String) -> some ViewModifier {
        AccessibilityLabelModifier(label: label)
    }
    
    static func testingValue<T>(_ value: T) -> some ViewModifier {
        AccessibilityValueModifier(value: "\(value)")
    }
}

// MARK: - View Modifiers
struct AccessibilityIdentifierModifier: ViewModifier {
    let id: String
    
    func body(content: Content) -> some View {
        content.accessibilityIdentifier(id)
    }
}

struct AccessibilityLabelModifier: ViewModifier {
    let label: String
    
    func body(content: Content) -> some View {
        content.accessibilityLabel(label)
    }
}

struct AccessibilityValueModifier: ViewModifier {
    let value: String
    
    func body(content: Content) -> some View {
        content.accessibilityValue(value)
    }
}

// MARK: - Testing Data Injection
struct TestingDataProvider {
    static var mockAlarmTime: Date? {
        guard UITestingHelper.isUITesting else { return nil }
        
        if let timeString = ProcessInfo.processInfo.environment["MOCK_ALARM_TIME"] {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.date(from: timeString)
        }
        
        return nil
    }
    
    static var mockCurrentTime: Date? {
        guard UITestingHelper.isUITesting else { return nil }
        
        if let timeString = ProcessInfo.processInfo.environment["MOCK_CURRENT_TIME"] {
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: timeString)
        }
        
        return nil
    }
    
    static var mockVolume: Float? {
        guard UITestingHelper.isUITesting else { return nil }
        
        if let volumeString = ProcessInfo.processInfo.environment["MOCK_VOLUME"] {
            return Float(volumeString)
        }
        
        return nil
    }
    
    static var shouldSimulateError: Bool {
        UITestingHelper.isUITesting && 
        ProcessInfo.processInfo.arguments.contains("SIMULATE_ERROR")
    }
}

// MARK: - View Extensions for Testing
extension View {
    func testingIdentifier(_ id: UITestingHelper.AccessibilityID) -> some View {
        modifier(UITestingHelper.accessibilityIdentifier(id))
    }
    
    func testingLabel(_ label: String) -> some View {
        modifier(UITestingHelper.testingLabel(label))
    }
    
    func testingValue<T>(_ value: T) -> some View {
        modifier(UITestingHelper.testingValue(value))
    }
    
    func disableAnimationsIfTesting() -> some View {
        animation(UITestingHelper.shouldSkipAnimations ? nil : .default, value: UUID())
    }
}

// MARK: - Performance Testing Support
struct PerformanceTestingOverlay: View {
    @StateObject private var metrics = PerformanceMetrics.shared
    
    var body: some View {
        if UITestingHelper.isPerformanceTesting {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("FPS: \(metrics.currentFPS, specifier: "%.1f")")
                        Text("Memory: \(metrics.memoryUsageMB, specifier: "%.1f")MB")
                        Text("CPU: \(metrics.cpuUsage, specifier: "%.1f")%")
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding()
                }
            }
            .testingIdentifier(.performanceMetrics)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Error Simulation for Testing
struct TestingErrorHandler {
    static func simulateErrorIfNeeded() -> AppError? {
        guard TestingDataProvider.shouldSimulateError else { return nil }
        
        let errorType = ProcessInfo.processInfo.environment["SIMULATE_ERROR_TYPE"] ?? "audio"
        
        switch errorType {
        case "audio":
            return AppError.audioError(.setupFailed)
        case "brightness":
            return AppError.brightnessError(.adjustmentFailed)
        case "permission":
            return AppError.permissionDenied(.notifications)
        default:
            return AppError.unknown("Simulated error for testing")
        }
    }
}
