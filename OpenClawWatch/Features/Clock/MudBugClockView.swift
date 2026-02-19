// MudBugClockView.swift
// MudBug watchOS Client
//
// An animated crawfish clock where the claws serve as watch hands.
// Left claw = hour hand, right claw = minute hand.
// Uses TimelineView for smooth real-time rotation and
// Liquid Glass materials for depth.

import SwiftUI

struct MudBugClockView: View {
    // Brand colors
    private let clawOrange = Color(red: 1.0, green: 0.45, blue: 0.1)
    private let clawAmber = Color(red: 0.95, green: 0.6, blue: 0.15)
    private let bodyDark = Color(red: 0.35, green: 0.12, blue: 0.05)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0)) { timeline in
            let date = timeline.date
            let calendar = Calendar.current
            let hour = Double(calendar.component(.hour, from: date) % 12)
            let minute = Double(calendar.component(.minute, from: date))
            let second = Double(calendar.component(.second, from: date))

            // Smooth angles
            let hourAngle = (hour + minute / 60.0) * 30.0   // 360° / 12
            let minuteAngle = (minute + second / 60.0) * 6.0 // 360° / 60

            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

                ZStack {
                    // Hour markers
                    hourMarkers(size: size, center: center)

                    // Glow behind claws
                    clawGlow(angle: hourAngle, length: size * 0.28, center: center)
                    clawGlow(angle: minuteAngle, length: size * 0.38, center: center)

                    // Left claw = hour hand
                    clawHand(
                        angle: hourAngle,
                        length: size * 0.28,
                        width: size * 0.09,
                        pincerSpread: 22,
                        center: center
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [clawOrange, clawAmber],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )

                    // Right claw = minute hand
                    clawHand(
                        angle: minuteAngle,
                        length: size * 0.38,
                        width: size * 0.07,
                        pincerSpread: 18,
                        center: center
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [clawOrange.opacity(0.9), clawAmber],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )

                    // Crawfish body (center)
                    crawfishBody(size: size, center: center)

                    // Center jewel
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [clawOrange, bodyDark],
                                center: .center,
                                startRadius: 0,
                                endRadius: size * 0.04
                            )
                        )
                        .frame(width: size * 0.08, height: size * 0.08)
                        .position(center)
                        .shadow(color: clawOrange.opacity(0.6), radius: 4)

                    // Second dot
                    secondDot(angle: Double(second) * 6.0, radius: size * 0.42, center: center)

                    // "MudBug" label
                    Text("MudBug")
                        .font(.system(size: size * 0.075, weight: .bold, design: .rounded))
                        .foregroundStyle(clawOrange.opacity(0.7))
                        .position(x: center.x, y: center.y + size * 0.20)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }

    // MARK: - Claw Hand Shape

    private func clawHand(
        angle: Double,
        length: CGFloat,
        width: CGFloat,
        pincerSpread: Double,
        center: CGPoint
    ) -> some View {
        let radians = Angle(degrees: angle - 90).radians

        return Canvas { context, _ in
            let armEnd = CGPoint(
                x: center.x + cos(radians) * length,
                y: center.y + sin(radians) * length
            )

            // Main arm
            var arm = Path()
            let perpX = -sin(radians) * width / 2
            let perpY = cos(radians) * width / 2
            arm.move(to: CGPoint(x: center.x + perpX, y: center.y + perpY))
            arm.addLine(to: CGPoint(x: armEnd.x + perpX * 0.3, y: armEnd.y + perpY * 0.3))
            arm.addLine(to: CGPoint(x: armEnd.x - perpX * 0.3, y: armEnd.y - perpY * 0.3))
            arm.addLine(to: CGPoint(x: center.x - perpX, y: center.y - perpY))
            arm.closeSubpath()
            context.fill(arm, with: .linearGradient(
                Gradient(colors: [clawOrange, clawAmber]),
                startPoint: center,
                endPoint: armEnd
            ))

            // Left pincer
            let pincerAngleL = Angle(degrees: angle - 90 - pincerSpread).radians
            let pincerTipL = CGPoint(
                x: armEnd.x + cos(pincerAngleL) * length * 0.25,
                y: armEnd.y + sin(pincerAngleL) * length * 0.25
            )
            var pincerL = Path()
            pincerL.move(to: CGPoint(x: armEnd.x + perpX * 0.3, y: armEnd.y + perpY * 0.3))
            pincerL.addQuadCurve(
                to: pincerTipL,
                control: CGPoint(
                    x: armEnd.x + cos(pincerAngleL) * length * 0.15 + perpX * 0.5,
                    y: armEnd.y + sin(pincerAngleL) * length * 0.15 + perpY * 0.5
                )
            )
            pincerL.addLine(to: armEnd)
            pincerL.closeSubpath()
            context.fill(pincerL, with: .linearGradient(
                Gradient(colors: [clawAmber, clawOrange.opacity(0.7)]),
                startPoint: armEnd,
                endPoint: pincerTipL
            ))

            // Right pincer
            let pincerAngleR = Angle(degrees: angle - 90 + pincerSpread).radians
            let pincerTipR = CGPoint(
                x: armEnd.x + cos(pincerAngleR) * length * 0.25,
                y: armEnd.y + sin(pincerAngleR) * length * 0.25
            )
            var pincerR = Path()
            pincerR.move(to: CGPoint(x: armEnd.x - perpX * 0.3, y: armEnd.y - perpY * 0.3))
            pincerR.addQuadCurve(
                to: pincerTipR,
                control: CGPoint(
                    x: armEnd.x + cos(pincerAngleR) * length * 0.15 - perpX * 0.5,
                    y: armEnd.y + sin(pincerAngleR) * length * 0.15 - perpY * 0.5
                )
            )
            pincerR.addLine(to: armEnd)
            pincerR.closeSubpath()
            context.fill(pincerR, with: .linearGradient(
                Gradient(colors: [clawAmber, clawOrange.opacity(0.7)]),
                startPoint: armEnd,
                endPoint: pincerTipR
            ))
        }
    }

    // MARK: - Crawfish Body

    private func crawfishBody(size: CGFloat, center: CGPoint) -> some View {
        Canvas { context, _ in
            // Oval body
            let bodyWidth = size * 0.14
            let bodyHeight = size * 0.18
            let bodyRect = CGRect(
                x: center.x - bodyWidth / 2,
                y: center.y - bodyHeight / 2,
                width: bodyWidth,
                height: bodyHeight
            )
            let body = Path(ellipseIn: bodyRect)
            context.fill(body, with: .linearGradient(
                Gradient(colors: [bodyDark, Color(red: 0.5, green: 0.18, blue: 0.08)]),
                startPoint: CGPoint(x: center.x, y: center.y - bodyHeight / 2),
                endPoint: CGPoint(x: center.x, y: center.y + bodyHeight / 2)
            ))

            // Gloss highlight
            let glossRect = CGRect(
                x: center.x - bodyWidth * 0.3,
                y: center.y - bodyHeight * 0.35,
                width: bodyWidth * 0.6,
                height: bodyHeight * 0.3
            )
            let gloss = Path(ellipseIn: glossRect)
            context.fill(gloss, with: .color(.white.opacity(0.15)))

            // Eyes
            let eyeSize = size * 0.025
            let eyeY = center.y - bodyHeight * 0.35
            let eyeOffsetX = bodyWidth * 0.35

            let leftEye = Path(ellipseIn: CGRect(
                x: center.x - eyeOffsetX - eyeSize,
                y: eyeY - eyeSize,
                width: eyeSize * 2,
                height: eyeSize * 2
            ))
            let rightEye = Path(ellipseIn: CGRect(
                x: center.x + eyeOffsetX - eyeSize,
                y: eyeY - eyeSize,
                width: eyeSize * 2,
                height: eyeSize * 2
            ))
            context.fill(leftEye, with: .color(clawOrange))
            context.fill(rightEye, with: .color(clawOrange))

            // Tail segments (below body)
            for i in 1...3 {
                let segY = center.y + bodyHeight / 2 + CGFloat(i) * size * 0.025
                let segWidth = bodyWidth * (1.0 - CGFloat(i) * 0.2)
                let segHeight = size * 0.018
                let segRect = CGRect(
                    x: center.x - segWidth / 2,
                    y: segY,
                    width: segWidth,
                    height: segHeight
                )
                let seg = Path(roundedRect: segRect, cornerRadius: segHeight / 2)
                context.fill(seg, with: .color(bodyDark.opacity(1.0 - Double(i) * 0.15)))
            }

            // Tail fan
            let fanY = center.y + bodyHeight / 2 + size * 0.10
            let fanWidth = bodyWidth * 0.25
            for offset in [-1.0, 0.0, 1.0] {
                let fanRect = CGRect(
                    x: center.x + CGFloat(offset) * fanWidth * 0.6 - fanWidth * 0.3,
                    y: fanY,
                    width: fanWidth * 0.6,
                    height: size * 0.03
                )
                let fan = Path(ellipseIn: fanRect)
                context.fill(fan, with: .color(bodyDark.opacity(0.6)))
            }

            // Antennae
            var leftAntenna = Path()
            leftAntenna.move(to: CGPoint(x: center.x - bodyWidth * 0.3, y: center.y - bodyHeight * 0.4))
            leftAntenna.addQuadCurve(
                to: CGPoint(x: center.x - size * 0.12, y: center.y - size * 0.16),
                control: CGPoint(x: center.x - size * 0.15, y: center.y - bodyHeight * 0.3)
            )
            context.stroke(leftAntenna, with: .color(clawOrange.opacity(0.5)), lineWidth: 1.0)

            var rightAntenna = Path()
            rightAntenna.move(to: CGPoint(x: center.x + bodyWidth * 0.3, y: center.y - bodyHeight * 0.4))
            rightAntenna.addQuadCurve(
                to: CGPoint(x: center.x + size * 0.12, y: center.y - size * 0.16),
                control: CGPoint(x: center.x + size * 0.15, y: center.y - bodyHeight * 0.3)
            )
            context.stroke(rightAntenna, with: .color(clawOrange.opacity(0.5)), lineWidth: 1.0)

            // Legs (3 per side)
            for i in 0..<3 {
                let legY = center.y - bodyHeight * 0.1 + CGFloat(i) * size * 0.04
                let legLength = size * 0.06

                var leftLeg = Path()
                leftLeg.move(to: CGPoint(x: center.x - bodyWidth / 2, y: legY))
                leftLeg.addLine(to: CGPoint(x: center.x - bodyWidth / 2 - legLength, y: legY + size * 0.015))
                context.stroke(leftLeg, with: .color(bodyDark.opacity(0.7)), lineWidth: 1.5)

                var rightLeg = Path()
                rightLeg.move(to: CGPoint(x: center.x + bodyWidth / 2, y: legY))
                rightLeg.addLine(to: CGPoint(x: center.x + bodyWidth / 2 + legLength, y: legY + size * 0.015))
                context.stroke(rightLeg, with: .color(bodyDark.opacity(0.7)), lineWidth: 1.5)
            }
        }
    }

    // MARK: - Hour Markers

    private func hourMarkers(size: CGFloat, center: CGPoint) -> some View {
        Canvas { context, _ in
            let radius = size * 0.44
            for i in 0..<12 {
                let angle = Angle(degrees: Double(i) * 30 - 90).radians
                let dotPos = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                let isCardinal = i % 3 == 0
                let dotSize = isCardinal ? size * 0.025 : size * 0.012

                let dot = Path(ellipseIn: CGRect(
                    x: dotPos.x - dotSize,
                    y: dotPos.y - dotSize,
                    width: dotSize * 2,
                    height: dotSize * 2
                ))
                context.fill(dot, with: .color(
                    isCardinal ? clawOrange.opacity(0.8) : .white.opacity(0.3)
                ))
            }
        }
    }

    // MARK: - Claw Glow

    private func clawGlow(angle: Double, length: CGFloat, center: CGPoint) -> some View {
        let radians = Angle(degrees: angle - 90).radians
        let tipPos = CGPoint(
            x: center.x + cos(radians) * length,
            y: center.y + sin(radians) * length
        )

        return Circle()
            .fill(
                RadialGradient(
                    colors: [clawOrange.opacity(0.3), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 20
                )
            )
            .frame(width: 40, height: 40)
            .position(tipPos)
            .blur(radius: 8)
    }

    // MARK: - Second Dot

    private func secondDot(angle: Double, radius: CGFloat, center: CGPoint) -> some View {
        let radians = Angle(degrees: angle - 90).radians
        let pos = CGPoint(
            x: center.x + cos(radians) * radius,
            y: center.y + sin(radians) * radius
        )

        return Circle()
            .fill(clawOrange)
            .frame(width: 4, height: 4)
            .position(pos)
            .shadow(color: clawOrange.opacity(0.8), radius: 3)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MudBugClockView()
            .padding(10)
    }
}
