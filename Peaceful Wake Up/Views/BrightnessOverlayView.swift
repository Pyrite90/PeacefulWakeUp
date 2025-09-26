//
//  BrightnessOverlayView.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/11/25.
//

import SwiftUI

struct BrightnessOverlayView: View {
    let currentBrightness: CGFloat
    let showBlackOverlay: Bool
    let currentTime: Date
    let onTap: () -> Void
    let setBrightness: (CGFloat) -> Void
    
    var body: some View {
        Group {
            // Visual brightness overlay for simulator
            if currentBrightness < 1.0 && !showBlackOverlay {
                Color.black
                    .opacity(1.0 - Double(currentBrightness))
                    .ignoresSafeArea(.all)
                    .allowsHitTesting(false)
            }
            
            // Black overlay for inactivity with time display
            if showBlackOverlay {
                ZStack {
                    Color.black
                        .ignoresSafeArea(.all)
                    
                    // Large translucent white time display
                    Text(timeString)
                        .font(.system(size: 72, weight: .thin, design: .default))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .onAppear {
                    // Set brightness to minimum when overlay appears
                    setBrightness(0.01)
                }
                .onTapGesture {
                    onTap()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: currentTime)
    }
}

#Preview {
    BrightnessOverlayView(
        currentBrightness: 0.5,
        showBlackOverlay: true,
        currentTime: Date(),
        onTap: {},
        setBrightness: { _ in }
    )
}
