//
//  SparklineView.swift
//  Stocks
//

import SwiftUI

struct SparklineView: View {
    let values: [Double]
    let baseline: Double?
    let isPositive: Bool

    private var lineColor: Color {
        isPositive
            ? Color(red: 0.0, green: 0.78, blue: 0.33)
            : Color(red: 1.0, green: 0.27, blue: 0.23)
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            if values.count >= 2,
               let layout = SparklineLayout.build(values: values, baseline: baseline, size: size) {
                ZStack(alignment: .topLeading) {
                    layout.fillPath
                        .fill(
                            LinearGradient(
                                colors: [lineColor.opacity(0.42), lineColor.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    if let y = layout.baselineY {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(lineColor.opacity(0.45))
                    }
                    layout.linePath
                        .stroke(lineColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.12))
            }
        }
        .accessibilityHidden(true)
    }
}

private struct SparklineLayout {
    let linePath: Path
    let fillPath: Path
    let baselineY: CGFloat?

    static func build(values: [Double], baseline: Double?, size: CGSize) -> SparklineLayout? {
        guard values.count >= 2, size.width > 0, size.height > 0 else { return nil }

        var minV = values.min() ?? 0
        var maxV = values.max() ?? 1
        if let b = baseline {
            minV = min(minV, b)
            maxV = max(maxV, b)
        }
        let span = max(maxV - minV, 1e-9)
        let n = values.count
        let pad: CGFloat = 1

        func y(for value: Double) -> CGFloat {
            pad + (1 - CGFloat((value - minV) / span)) * (size.height - 2 * pad)
        }

        func x(at index: Int) -> CGFloat {
            guard n > 1 else { return size.width / 2 }
            return CGFloat(index) / CGFloat(n - 1) * (size.width - 2 * pad) + pad
        }

        var stroke = Path()
        stroke.move(to: CGPoint(x: x(at: 0), y: y(for: values[0])))
        for i in 1..<n {
            stroke.addLine(to: CGPoint(x: x(at: i), y: y(for: values[i])))
        }

        let linePath = stroke

        var fill = stroke
        let last = CGPoint(x: x(at: n - 1), y: y(for: values[n - 1]))
        let firstX = x(at: 0)
        fill.addLine(to: CGPoint(x: last.x, y: size.height))
        fill.addLine(to: CGPoint(x: firstX, y: size.height))
        fill.closeSubpath()

        let baselineY: CGFloat?
        if let b = baseline {
            let yb = y(for: b)
            baselineY = min(max(yb, 0), size.height)
        } else {
            baselineY = nil
        }

        return SparklineLayout(linePath: linePath, fillPath: fill, baselineY: baselineY)
    }
}

#Preview("Sparkline") {
    HStack {
        SparklineView(
            values: (0..<40).map { Double($0) * 0.3 + sin(Double($0) * 0.4) * 3 },
            baseline: 8,
            isPositive: true
        )
        .frame(width: 72, height: 40)
        SparklineView(
            values: (0..<40).map { 20 - Double($0) * 0.25 },
            baseline: 18,
            isPositive: false
        )
        .frame(width: 72, height: 40)
    }
    .padding()
    .background(Color.black)
}
