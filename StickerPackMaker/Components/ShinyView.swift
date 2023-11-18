//
//  ShinyView.swift
//
//
//  Created by Michael Verges on 7/31/20.
//

import SwiftUI
import CoreMotion
#if os(macOS)
import AppKit
#endif

extension View {
    func shinySticker() -> some View {
        modifier(ShinySticker())
    }
}

struct ShinySticker: ViewModifier {
    @StateObject var model = MotionManager.main

    var position: CGSize {
        let x = 0 - (CGFloat(model.roll) / .pi * 4) * 300
        let y = 0 - (CGFloat(model.pitch) / .pi * 4) * 300
        let clampX: CGFloat = min(x, 300)
        let clampY: CGFloat = min(y, 300)
        return CGSize(width: clampX, height: clampY)
    }

    var surface: LinearGradient = LinearGradient(colors: [
        .red, .red, .red,
        .red, .orange, .yellow, .green, .blue, .purple, .pink,
        .red, .orange, .yellow, .green, .blue, .purple, .pink,
        .red, .orange, .yellow, .green, .blue, .purple, .pink
    ], startPoint: .topLeading, endPoint: .bottomTrailing)


    func body(content: Content) -> some View {
        content
            .overlay {
                Rectangle()
                    .fill(self.surface)
                    .visualEffect { content, geometryProxy in
                        return content.scaleEffect(10)
                    }
                    .offset(self.position)
                    .opacity(0.3)
            }

    }
}

#Preview {
    //    Image(.sticker)
    Image(.nemo)
        .resizable()
        .scaledToFit()
        .modifier(ShinySticker())
        .padding(20)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 50.0, style: .continuous))
        .frame(width: 300, height: 300, alignment: .center)
}

