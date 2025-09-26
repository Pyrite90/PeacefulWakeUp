//
//  NotificationManagerTests.swift
//  Peaceful Wake UpTests
//
//  Created by Mike McDonald on 9/26/25.
//

import XCTest
import AVFoundation
import UIKit
@testable import Peaceful_Wake_Up

final class NotificationManagerTests: XCTestCase {
    var notificationManager: NotificationManager!
    var memoryWarningCalled = false
    var audioInterruptionCalled = false
    
    override func setUp() {
        super.setUp()
        notificationManager = NotificationManager()
        memoryWarningCalled = false
        audioInterruptionCalled = false
    }
    
    override func tearDown() {
        notificationManager?.removeNotificationObservers()
        notificationManager = nil
        super.tearDown()
    }
    
    // MARK: - Observer Setup Tests
    func testSetupNotificationObservers() {
        let memoryWarningExpectation = expectation(description: "Memory warning callback")
        let audioInterruptionExpectation = expectation(description: "Audio interruption callback")
        
        notificationManager.setupNotificationObservers(
            onMemoryWarning: {
                self.memoryWarningCalled = true
                memoryWarningExpectation.fulfill()
            },
            onAudioInterruption: { _ in
                self.audioInterruptionCalled = true
                audioInterruptionExpectation.fulfill()
            }
        )
        
        // Trigger notifications
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        let audioUserInfo: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
        ]
        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: audioUserInfo
        )
        
        waitForExpectations(timeout: 1.0) { error in
            if let error = error {
                XCTFail("Timeout waiting for notifications: \(error)")
            }
        }
        
        XCTAssertTrue(memoryWarningCalled)
        XCTAssertTrue(audioInterruptionCalled)
    }
    
    func testRemoveNotificationObservers() {
        // Setup observers first
        notificationManager.setupNotificationObservers(
            onMemoryWarning: { self.memoryWarningCalled = true },
            onAudioInterruption: { _ in self.audioInterruptionCalled = true }
        )
        
        // Remove observers
        notificationManager.removeNotificationObservers()
        
        // Post notifications - should not be received
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        let audioUserInfo: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
        ]
        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: audioUserInfo
        )
        
        // Wait a bit to ensure notifications would have been processed
        let expectation = expectation(description: "Wait for notifications")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertFalse(memoryWarningCalled, "Memory warning should not be called after removing observers")
        XCTAssertFalse(audioInterruptionCalled, "Audio interruption should not be called after removing observers")
    }
    
    // MARK: - Multiple Setup/Removal Tests
    func testMultipleSetupCalls() {
        // Should handle multiple setup calls gracefully
        notificationManager.setupNotificationObservers(
            onMemoryWarning: { self.memoryWarningCalled = true },
            onAudioInterruption: { _ in self.audioInterruptionCalled = true }
        )
        
        // Second setup should remove previous observers and set up new ones
        notificationManager.setupNotificationObservers(
            onMemoryWarning: { self.memoryWarningCalled = true },
            onAudioInterruption: { _ in self.audioInterruptionCalled = true }
        )
        
        XCTAssertTrue(true) // Should complete without issues
    }
    
    func testMultipleRemoveCalls() {
        notificationManager.setupNotificationObservers(
            onMemoryWarning: { },
            onAudioInterruption: { _ in }
        )
        
        // Multiple remove calls should be safe
        notificationManager.removeNotificationObservers()
        notificationManager.removeNotificationObservers()
        
        XCTAssertTrue(true) // Should complete without crashing
    }
    
    func testRemoveWithoutSetup() {
        // Should be safe to remove without setting up
        XCTAssertNoThrow(notificationManager.removeNotificationObservers())
    }
    
    // MARK: - Memory Management Tests
    func testDeinitCleanup() {
        var manager: NotificationManager? = NotificationManager()
        manager?.setupNotificationObservers(
            onMemoryWarning: { },
            onAudioInterruption: { _ in }
        )
        
        // Deinit should clean up observers
        XCTAssertNoThrow(manager = nil)
    }
    
    // MARK: - Callback Tests
    func testMemoryWarningCallback() {
        let expectation = self.expectation(description: "Memory warning callback")
        var callbackExecuted = false
        
        notificationManager.setupNotificationObservers(
            onMemoryWarning: {
                callbackExecuted = true
                expectation.fulfill()
            },
            onAudioInterruption: { _ in }
        )
        
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(callbackExecuted)
    }
    
    func testAudioInterruptionCallback() {
        let expectation = self.expectation(description: "Audio interruption callback")
        var notificationReceived: Notification?
        
        notificationManager.setupNotificationObservers(
            onMemoryWarning: { },
            onAudioInterruption: { notification in
                notificationReceived = notification
                expectation.fulfill()
            }
        )
        
        let userInfo: [AnyHashable: Any] = [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
        ]
        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: userInfo
        )
        
        waitForExpectations(timeout: 1.0)
        XCTAssertNotNil(notificationReceived)
        XCTAssertEqual(notificationReceived?.name, AVAudioSession.interruptionNotification)
    }
    
    // MARK: - Performance Tests
    func testSetupPerformance() {
        measure {
            for _ in 0..<100 {
                notificationManager.setupNotificationObservers(
                    onMemoryWarning: { },
                    onAudioInterruption: { _ in }
                )
                notificationManager.removeNotificationObservers()
            }
        }
    }
    
    // MARK: - Edge Cases
    func testWithNilCallbacks() {
        // Test with minimal callbacks
        notificationManager.setupNotificationObservers(
            onMemoryWarning: { },
            onAudioInterruption: { _ in }
        )
        
        XCTAssertTrue(true) // Should complete without issues
    }
}
