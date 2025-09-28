//
//  AdvancedViewOptimizations.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/27/25.
//

import SwiftUI
import Foundation

// MARK: - SwiftUI Performance Optimizations
enum AdvancedViewOptimizations {
    
    // MARK: - Time Update Optimization
    static func shouldUpdateTime(_ oldTime: Date, _ newTime: Date) -> Bool {
        // Only update if minutes have changed (reduces second-by-second updates)
        let calendar = Calendar.current
        let oldComponents = calendar.dateComponents([.hour, .minute], from: oldTime)
        let newComponents = calendar.dateComponents([.hour, .minute], from: newTime)
        
        return oldComponents.hour != newComponents.hour || 
               oldComponents.minute != newComponents.minute
    }
    
    // MARK: - Brightness Update Optimization
    static func shouldUpdateBrightness(_ oldBrightness: CGFloat, _ newBrightness: CGFloat) -> Bool {
        // Only update if brightness change is significant (> 1%)
        return abs(oldBrightness - newBrightness) > 0.01
    }
    
    // MARK: - Volume Update Optimization
    static func shouldUpdateVolume(_ oldVolume: Float, _ newVolume: Float) -> Bool {
        // Only update if volume change is significant (> 1%)
        return abs(oldVolume - newVolume) > 0.01
    }
}

// MARK: - Memory-Efficient View Modifiers
struct ConditionalModifier<T: ViewModifier>: ViewModifier {
    let condition: Bool
    let modifier: T
    
    func body(content: Content) -> some View {
        if condition {
            content.modifier(modifier)
        } else {
            content
        }
    }
}

extension View {
    func conditionalModifier<T: ViewModifier>(
        _ condition: Bool,
        modifier: T
    ) -> some View {
        self.modifier(ConditionalModifier(condition: condition, modifier: modifier))
    }
    
    func profilePerformance(_ identifier: String) -> some View {
        self.onAppear {
            let start = CFAbsoluteTimeGetCurrent()
            DispatchQueue.main.async {
                let renderTime = CFAbsoluteTimeGetCurrent() - start
                if renderTime > 0.016 { // > 16ms (60fps threshold)
                    print("⚠️ Slow render detected in \(identifier): \(renderTime * 1000)ms")
                }
            }
        }
    }
}