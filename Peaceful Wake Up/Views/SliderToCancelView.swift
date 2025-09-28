//
//  SliderToCancelView.swift
//  Peaceful Wake Up
//
//  Created by Mike McDonald on 9/11/25.
//

import SwiftUI

struct SliderToCancelView: View {
    @State private var sliderOffset: CGFloat = 0
    @State private var sliderWidth: CGFloat = 0
    let onCancel: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 32.5)
                    .fill(.white.opacity(0.2))
                    .frame(height: 65)
                
                // Slider thumb
                RoundedRectangle(cornerRadius: 29)
                    .fill(.white.opacity(0.8))
                    .frame(width: 58, height: 58)
                    .offset(x: sliderOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let maxOffset = geometry.size.width - 58
                                sliderOffset = max(0, min(value.translation.width, maxOffset))
                            }
                            .onEnded { value in
                                let maxOffset = geometry.size.width - 58
                                
                                if sliderOffset > maxOffset * 0.8 {
                                    // Slider moved far enough - cancel alarm
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        sliderOffset = maxOffset
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        onCancel()
                                    }
                                } else {
                                    // Snap back to start
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        sliderOffset = 0
                                    }
                                }
                            }
                    )
                
                // Cancel text
                HStack {
                    Spacer()
                    Text("Cancel Alarm")
                        .font(.headline)
                        .fontWeight(.light)
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                }
            }
            .onAppear {
                sliderWidth = geometry.size.width
            }
        }
        .frame(height: 65)
    }
}

#Preview {
    SliderToCancelView(onCancel: {})
        .padding()
        .background(.black)
}