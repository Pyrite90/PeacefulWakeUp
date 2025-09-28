//
//  CircuitBreaker.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/27/25.
//

import Foundation

// MARK: - Circuit Breaker Pattern for Error Recovery
class CircuitBreaker {
    enum State {
        case closed    // Normal operation
        case open      // Failing, blocking requests
        case halfOpen  // Testing if service recovered
    }
    
    private let failureThreshold: Int
    private let recoveryTimeout: TimeInterval
    private let resetTimeout: TimeInterval
    
    private var state: State = .closed
    private var failureCount: Int = 0
    private var lastFailureTime: Date?
    private var lastAttemptTime: Date?
    
    private let queue = DispatchQueue(label: "com.peacefulwakeup.circuitbreaker", qos: .utility)
    
    init(failureThreshold: Int = 5, recoveryTimeout: TimeInterval = 30.0, resetTimeout: TimeInterval = 60.0) {
        self.failureThreshold = failureThreshold
        self.recoveryTimeout = recoveryTimeout
        self.resetTimeout = resetTimeout
    }
    
    func execute<T>(_ operation: () throws -> T) throws -> T {
        return try queue.sync {
            switch state {
            case .open:
                // Check if enough time has passed to attempt recovery
                if let lastFailure = lastFailureTime,
                   Date().timeIntervalSince(lastFailure) > recoveryTimeout {
                    state = .halfOpen
                    return try attemptOperation(operation)
                } else {
                    throw CircuitBreakerError.circuitOpen
                }
                
            case .halfOpen:
                return try attemptOperation(operation)
                
            case .closed:
                return try attemptOperation(operation)
            }
        }
    }
    
    private func attemptOperation<T>(_ operation: () throws -> T) throws -> T {
        lastAttemptTime = Date()
        
        do {
            let result = try operation()
            onSuccess()
            return result
        } catch {
            onFailure()
            throw error
        }
    }
    
    private func onSuccess() {
        failureCount = 0
        state = .closed
        lastFailureTime = nil
    }
    
    private func onFailure() {
        failureCount += 1
        lastFailureTime = Date()
        
        if failureCount >= failureThreshold {
            state = .open
        }
    }
    
    func getCurrentState() -> State {
        return queue.sync { state }
    }
    
    func reset() {
        queue.sync {
            state = .closed
            failureCount = 0
            lastFailureTime = nil
            lastAttemptTime = nil
        }
    }
}

enum CircuitBreakerError: LocalizedError {
    case circuitOpen
    
    var errorDescription: String? {
        switch self {
        case .circuitOpen:
            return "Circuit breaker is open - service temporarily unavailable"
        }
    }
}

// MARK: - Retry Mechanism with Exponential Backoff
class RetryMechanism {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let backoffMultiplier: Double
    
    init(maxRetries: Int = 3, baseDelay: TimeInterval = 1.0, maxDelay: TimeInterval = 30.0, backoffMultiplier: Double = 2.0) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
    }
    
    func execute<T>(_ operation: @escaping () throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try operation()
            } catch {
                lastError = error
                
                // Don't delay after the last attempt
                if attempt < maxRetries {
                    let delay = min(baseDelay * pow(backoffMultiplier, Double(attempt)), maxDelay)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? RetryError.maxRetriesExceeded
    }
}

enum RetryError: LocalizedError {
    case maxRetriesExceeded
    
    var errorDescription: String? {
        switch self {
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        }
    }
}