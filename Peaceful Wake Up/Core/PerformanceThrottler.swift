//
//  PerformanceThrottler.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/27/25.
//

import Foundation

// MARK: - Performance Throttling
class PerformanceThrottler {
    private static var throttlers: [String: PerformanceThrottler] = [:]
    
    private let minimumInterval: TimeInterval
    private var lastExecutionTime: Date?
    private let queue: DispatchQueue
    
    private init(minimumInterval: TimeInterval, queue: DispatchQueue = .main) {
        self.minimumInterval = minimumInterval
        self.queue = queue
    }
    
    static func shared(for identifier: String, minimumInterval: TimeInterval) -> PerformanceThrottler {
        if let existing = throttlers[identifier] {
            return existing
        }
        
        let throttler = PerformanceThrottler(minimumInterval: minimumInterval)
        throttlers[identifier] = throttler
        return throttler
    }
    
    func execute(_ operation: @escaping () -> Void) {
        let now = Date()
        
        if let lastTime = lastExecutionTime,
           now.timeIntervalSince(lastTime) < minimumInterval {
            // Skip execution if too soon
            return
        }
        
        lastExecutionTime = now
        
        queue.async {
            operation()
        }
    }
    
    func canExecute() -> Bool {
        guard let lastTime = lastExecutionTime else { return true }
        return Date().timeIntervalSince(lastTime) >= minimumInterval
    }
    
    static func reset() {
        throttlers.removeAll()
    }
}

// MARK: - Rate Limiter for Frequent Operations
class RateLimiter {
    private let maxOperationsPerWindow: Int
    private let timeWindow: TimeInterval
    private var operationTimes: [Date] = []
    private let queue = DispatchQueue(label: "com.peacefulwakeup.ratelimiter", qos: .utility)
    
    init(maxOperationsPerWindow: Int, timeWindow: TimeInterval) {
        self.maxOperationsPerWindow = maxOperationsPerWindow
        self.timeWindow = timeWindow
    }
    
    func canExecute() -> Bool {
        return queue.sync {
            let now = Date()
            let cutoffTime = now.addingTimeInterval(-timeWindow)
            
            // Remove old operations outside the time window
            operationTimes = operationTimes.filter { $0 > cutoffTime }
            
            return operationTimes.count < maxOperationsPerWindow
        }
    }
    
    func recordOperation() {
        queue.async { [weak self] in
            self?.operationTimes.append(Date())
        }
    }
    
    func executeIfAllowed(_ operation: @escaping () -> Void) -> Bool {
        if canExecute() {
            recordOperation()
            operation()
            return true
        }
        return false
    }
}

// MARK: - Performance Monitoring Extensions
// Note: Extensions should be added directly to the manager files to avoid protocol conformance issues\n// These are example implementations that should be integrated into the actual manager classes