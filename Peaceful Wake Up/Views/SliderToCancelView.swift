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
                RoundedRectangle(cornerRadius: 25)
                    .fill(.white.opacity(0.2))
                    .frame(height: 50)
                
                // Slider thumb
                RoundedRectangle(cornerRadius: 22.5)
                    .fill(.white.opacity(0.8))
                    .frame(width: 45, height: 45)
                    .offset(x: sliderOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let maxOffset = geometry.size.width - 45
                                sliderOffset = max(0, min(value.translation.width, maxOffset))
                            }
                            .onEnded { value in
                                let maxOffset = geometry.size.width - 45
                                
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
        .frame(height: 50)
    }
}

#Preview {
    SliderToCancelView(onCancel: {})
        .padding()
        .background(.black)
}