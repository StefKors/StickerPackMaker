//
//  ShapeView.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 22/11/2023.
//

import SwiftUI

struct OutlinePathView {

    static func draw(path sourcePath: CGPath, in rect: CGRect) -> Path {
        print("redraw \(rect.width.description)")
        let path = Path(sourcePath)

//        let boundingRect = path.boundingRect
//        let scaleX = rect.width/boundingRect.width
//        let scaleY = rect.height/boundingRect.height
        let scaled = path.applying(.init(scaleX: rect.width, y: -rect.height))
        let scaledBoundingRect = scaled.boundingRect
        let offsetX = scaledBoundingRect.midX - rect.midX
        let offsetY = scaledBoundingRect.midY - rect.midY
        return scaled.offsetBy(dx: -offsetX, dy: -offsetY)

        // Figure out how much bigger we need to make our path in order for it to fill the available space without clipping.
//        let multiplier = min(rect.width, rect.height)

//        // Create an affine transform that uses the multiplier for both dimensions equally.
//        let transform = CGAffineTransform(scaleX: rect.width, y: -rect.height)
//
//        // Apply that scale and send back the result.
//        return path.applying(transform)
    }
}


struct Triangle: Shape {
//    let sourcePath = CGPath
    /// The Unwrap logo as a Bezier path.
    var sourcePath: UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0.534, y: 0.5816))
        path.addCurve(to: CGPoint(x: 0.1877, y: 0.088), controlPoint1: CGPoint(x: 0.534, y: 0.5816), controlPoint2: CGPoint(x: 0.2529, y: 0.4205))
        path.addCurve(to: CGPoint(x: 0.9728, y: 0.8259), controlPoint1: CGPoint(x: 0.4922, y: 0.4949), controlPoint2: CGPoint(x: 1.0968, y: 0.4148))
        path.addCurve(to: CGPoint(x: 0.0397, y: 0.5431), controlPoint1: CGPoint(x: 0.7118, y: 0.5248), controlPoint2: CGPoint(x: 0.3329, y: 0.7442))
        path.addCurve(to: CGPoint(x: 0.6211, y: 0.0279), controlPoint1: CGPoint(x: 0.508, y: 1.1956), controlPoint2: CGPoint(x: 1.3042, y: 0.5345))
        path.addCurve(to: CGPoint(x: 0.6904, y: 0.3615), controlPoint1: CGPoint(x: 0.7282, y: 0.2481), controlPoint2: CGPoint(x: 0.6904, y: 0.3615))
        return path
    }

    static func drawPath(rect: CGRect) -> Path {
        print("drawPath redraw \(rect.width.description)")
        let bPath = UIBezierPath()
        bPath.move(to: CGPoint(x: 0.534, y: 0.5816))
        bPath.addCurve(to: CGPoint(x: 0.1877, y: 0.088), controlPoint1: CGPoint(x: 0.534, y: 0.5816), controlPoint2: CGPoint(x: 0.2529, y: 0.4205))
        bPath.addCurve(to: CGPoint(x: 0.9728, y: 0.8259), controlPoint1: CGPoint(x: 0.4922, y: 0.4949), controlPoint2: CGPoint(x: 1.0968, y: 0.4148))
        bPath.addCurve(to: CGPoint(x: 0.0397, y: 0.5431), controlPoint1: CGPoint(x: 0.7118, y: 0.5248), controlPoint2: CGPoint(x: 0.3329, y: 0.7442))
        bPath.addCurve(to: CGPoint(x: 0.6211, y: 0.0279), controlPoint1: CGPoint(x: 0.508, y: 1.1956), controlPoint2: CGPoint(x: 1.3042, y: 0.5345))
        bPath.addCurve(to: CGPoint(x: 0.6904, y: 0.3615), controlPoint1: CGPoint(x: 0.7282, y: 0.2481), controlPoint2: CGPoint(x: 0.6904, y: 0.3615))
        let path = Path(bPath.cgPath)

        // Figure out how much bigger we need to make our path in order for it to fill the available space without clipping.
        let multiplier = min(rect.width, rect.height)

        // Create an affine transform that uses the multiplier for both dimensions equally.
        let transform = CGAffineTransform(scaleX: multiplier, y: multiplier)

        // Apply that scale and send back the result.
        return path.applying(transform)
    }

    func path(in rect: CGRect) -> Path {
        print("redraw \(rect.width.description)")
        let path = Path(sourcePath.cgPath)

        // Figure out how much bigger we need to make our path in order for it to fill the available space without clipping.
        let multiplier = min(rect.width, rect.height)

        // Create an affine transform that uses the multiplier for both dimensions equally.
        let transform = CGAffineTransform(scaleX: multiplier, y: multiplier)

        // Apply that scale and send back the result.
        return path.applying(transform)

//        Path { path in
//            // 1
//            path.move(
//                to: CGPoint(
//                    x: 0,
//                    y: 100
//                )
//            )
//            // 2
//            path.addLine(
//                to: CGPoint(
//                    x: 100,
//                    y: 100)
//            )
//            // 3
//            path.addLine(
//                to: CGPoint(
//                    x: 50,
//                    y: 0)
//            )
//            // 4
//            path.closeSubpath()
//        }
    }
}

struct ShapeResizerView: View {
    @State private var isLarge: Bool = false

    var size: CGFloat {
        isLarge ? 200 : 20
    }
    var body: some View {
        VStack {
            HStack {
                Rectangle()
                    .foregroundColor(.blue)
                Circle()
                    .foregroundColor(.orange)
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .foregroundColor(.green)
//                Triangle()
//                    .foregroundColor(.blue)
            }
            .aspectRatio(3.0, contentMode: .fit)
            .frame(width: 200, height: 200, alignment: .center)
            .border(Color.black, width: 1)

            Canvas { context, size in
                context.stroke(
                    Triangle.drawPath(rect: CGRect(origin: .zero, size: size)),
                    with: .color(.green),
                    lineWidth: 4)
            }
            .frame(width: size, height: size, alignment: .center)
            .border(Color.blue)


//            Triangle()
//                .fill(.blue)
//                .scaledToFit()
//                .frame(width: size, height: size, alignment: .center)
//                .border(Color.black, width: 1)
        }
        .onTapGesture {
            withAnimation(.snappy) {
                isLarge.toggle()
            }
        }
    }
}

#Preview {
    ShapeResizerView()
}
