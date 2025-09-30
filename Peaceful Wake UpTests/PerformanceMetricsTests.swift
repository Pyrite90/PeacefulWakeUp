//
//  PerformanceMetricsTests.swift
//  Peaceful Wake UpTests
//
//  Created by Mike McDonald on 9/26/25.
//

import XCTest
@testable import Peaceful_Wake_Up

@MainActor
final class PerformanceMetricsTests: XCTestCase {
    var performanceMetrics: PerformanceMetrics!
    
    override func setUp() {
        super.setUp()
        performanceMetrics = PerformanceMetrics()
    }
    
    override func tearDown() {
        performanceMetrics = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    func testInitialState() {
        XCTAssertEqual(performanceMetrics.audioSetupTime, 0)
        XCTAssertEqual(performanceMetrics.brightnessChangeCount, 0)
        XCTAssertEqual(performanceMetrics.volumeChangeCount, 0)
    }
    
    // MARK: - Audio Setup Time Recording
    func testRecordAudioSetupTime() {
        let testTime: TimeInterval = 1.5
        
        performanceMetrics.recordAudioSetupTime(testTime)
        
        XCTAssertEqual(performanceMetrics.audioSetupTime, testTime)
    }
    
    func testRecordAudioSetupTimeOverwrite() {
        performanceMetrics.recordAudioSetupTime(1.0)
        performanceMetrics.recordAudioSetupTime(2.0)
        
        XCTAssertEqual(performanceMetrics.audioSetupTime, 2.0)
    }
    
    // MARK: - Brightness Change Tracking
    func testRecordBrightnessChange() {
        performanceMetrics.recordBrightnessChange()
        
        XCTAssertEqual(performanceMetrics.brightnessChangeCount, 1)
    }
    
    func testRecordMultipleBrightnessChanges() {
        for _ in 0..<5 {
            performanceMetrics.recordBrightnessChange()
        }
        
        XCTAssertEqual(performanceMetrics.brightnessChangeCount, 5)
    }
    
    func testRecordManyBrightnessChanges() {
        let changeCount = 1000
        for _ in 0..<changeCount {
            performanceMetrics.recordBrightnessChange()
        }
        
        XCTAssertEqual(performanceMetrics.brightnessChangeCount, changeCount)
    }
    
    // MARK: - Volume Change Tracking
    func testRecordVolumeChange() {
        performanceMetrics.recordVolumeChange()
        
        XCTAssertEqual(performanceMetrics.volumeChangeCount, 1)
    }
    
    func testRecordMultipleVolumeChanges() {
        for _ in 0..<3 {
            performanceMetrics.recordVolumeChange()
        }
        
        XCTAssertEqual(performanceMetrics.volumeChangeCount, 3)
    }
    
    // MARK: - Combined Metrics Tests
    func testRecordAllMetrics() {
        performanceMetrics.recordAudioSetupTime(0.5)
        performanceMetrics.recordBrightnessChange()
        performanceMetrics.recordBrightnessChange()
        performanceMetrics.recordVolumeChange()
        
        XCTAssertEqual(performanceMetrics.audioSetupTime, 0.5)
        XCTAssertEqual(performanceMetrics.brightnessChangeCount, 2)
        XCTAssertEqual(performanceMetrics.volumeChangeCount, 1)
    }
    
    // MARK: - Logging Tests
    func testLogMetrics() {
        // Test that logging doesn't crash
        XCTAssertNoThrow(performanceMetrics.logMetrics())
    }
    
    func testLogMetricsWithData() {
        performanceMetrics.recordAudioSetupTime(1.2)
        performanceMetrics.recordBrightnessChange()
        performanceMetrics.recordVolumeChange()
        
        XCTAssertNoThrow(performanceMetrics.logMetrics())
    }
    
    // MARK: - Edge Cases
    func testNegativeAudioSetupTime() {
        performanceMetrics.recordAudioSetupTime(-1.0)
        
        XCTAssertEqual(performanceMetrics.audioSetupTime, -1.0) // Should accept negative values for debugging
    }
    
    func testZeroAudioSetupTime() {
        performanceMetrics.recordAudioSetupTime(0.0)
        
        XCTAssertEqual(performanceMetrics.audioSetupTime, 0.0)
    }
    
    func testVeryLargeAudioSetupTime() {
        let largeTime: TimeInterval = 999999.0
        performanceMetrics.recordAudioSetupTime(largeTime)
        
        XCTAssertEqual(performanceMetrics.audioSetupTime, largeTime)
    }
    
    // MARK: - Performance Tests
    func testPerformanceOfRecording() {
        measure {
            for _ in 0..<1000 {
                performanceMetrics.recordBrightnessChange()
                performanceMetrics.recordVolumeChange()
            }
        }
    }
    
    func testPerformanceOfLogging() {
        // Set up some metrics
        performanceMetrics.recordAudioSetupTime(1.0)
        for _ in 0..<100 {
            performanceMetrics.recordBrightnessChange()
            performanceMetrics.recordVolumeChange()
        }
        
        measure {
            performanceMetrics.logMetrics()
        }
    }
}
