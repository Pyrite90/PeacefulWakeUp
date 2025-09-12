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
            
            // Black overlay for inactivity
            if showBlackOverlay {
                Color.black
                    .ignoresSafeArea(.all)
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
}

#Preview {
    BrightnessOverlayView(
        currentBrightness: 0.5,
        showBlackOverlay: false,
        onTap: {},
        setBrightness: { _ in }
    )
}