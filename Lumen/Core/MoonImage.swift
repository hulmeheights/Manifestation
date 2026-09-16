//
//  MoonImage.swift
//  Lumen
//
//  The moon, drawn to a PNG so it can be attached to a notification.
//
//  iOS gives you almost no control over how a notification looks — the small
//  icon is always your app icon, and the layout is the system's. The one real
//  lever is an attachment, which appears as a thumbnail on the right and
//  fills the banner when the notification is expanded. So the least we can do
//  is make that thumbnail tonight's actual moon.
//

import UIKit

enum MoonImage {

    /// Draws the phase at `fraction` through the lunation, matching MoonDisc.
    static func render(fraction: Double, side: CGFloat = 600, light: Bool = false) -> UIImage {
        let ground = light
            ? UIColor(red: 0.98, green: 0.98, blue: 0.976, alpha: 1)
            : UIColor(red: 0.027, green: 0.031, blue: 0.047, alpha: 1)
        let lit = light
            ? UIColor(red: 0.082, green: 0.09, blue: 0.102, alpha: 1)
            : UIColor(red: 1.0, green: 0.965, blue: 0.878, alpha: 1)
        let dark = light
            ? UIColor(red: 0.886, green: 0.89, blue: 0.878, alpha: 1)
            : UIColor(red: 0.067, green: 0.075, blue: 0.102, alpha: 1)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let size = CGSize(width: side, height: side)
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext

            ground.setFill()
            cg.fill(CGRect(origin: .zero, size: size))

            if !light {
                // A handful of stars, fixed rather than random so the image is
                // the same every time it's generated.
                lit.withAlphaComponent(0.55).setFill()
                let seeds: [(CGFloat, CGFloat, CGFloat)] = [
                    (0.10, 0.12, 1.6), (0.28, 0.07, 1.2), (0.46, 0.15, 1.8),
                    (0.70, 0.09, 1.3), (0.88, 0.18, 1.7), (0.16, 0.34, 1.1),
                    (0.84, 0.40, 1.5), (0.22, 0.78, 1.2), (0.62, 0.88, 1.4),
                    (0.90, 0.72, 1.1), (0.08, 0.60, 1.3), (0.52, 0.94, 1.5)
                ]
                for (x, y, r) in seeds {
                    let rect = CGRect(
                        x: x * side - r, y: y * side - r,
                        width: r * 2, height: r * 2
                    )
                    cg.fillEllipse(in: rect)
                }
            }

            let radius = side * 0.30
            let centre = CGPoint(x: side / 2, y: side / 2)
            let disc = CGRect(
                x: centre.x - radius, y: centre.y - radius,
                width: radius * 2, height: radius * 2
            )

            if !light {
                // Soft glow — the one light source in the whole app.
                cg.saveGState()
                cg.setShadow(
                    offset: .zero,
                    blur: side * 0.09,
                    color: lit.withAlphaComponent(0.55).cgColor
                )
                lit.setFill()
                cg.fillEllipse(in: disc.insetBy(dx: radius * 0.1, dy: radius * 0.1))
                cg.restoreGState()
            }

            // Dark disc.
            dark.setFill()
            cg.fillEllipse(in: disc)

            // Lit half — right while waxing, left while waning.
            let waxing = fraction < 0.5
            cg.saveGState()
            cg.addEllipse(in: disc)
            cg.clip()
            lit.setFill()
            cg.fill(
                CGRect(
                    x: waxing ? centre.x : disc.minX,
                    y: disc.minY,
                    width: radius,
                    height: radius * 2
                )
            )

            // Terminator.
            let k = abs(cos(2 * Double.pi * fraction))
            let gibbous = fraction > 0.25 && fraction < 0.75
            (gibbous ? lit : dark).setFill()
            cg.fillEllipse(
                in: CGRect(
                    x: centre.x - radius * k,
                    y: disc.minY,
                    width: radius * 2 * k,
                    height: radius * 2
                )
            )
            cg.restoreGState()
        }
    }


    // MARK: - The card
    //
    // The attachment is the only part of a notification an app is allowed to
    // design, so it is worth designing properly rather than shipping a bare
    // circle. This draws the same card the Live Activity draws: near-black
    // ground, stars, the glowing moon, your line in cream underneath.
    //
    // Square, because iOS crops the thumbnail to a square in the collapsed
    // banner and shows the whole thing once the banner is pulled down.

    static func card(fraction: Double, line: String, caption: String, side: CGFloat = 1000) -> UIImage {
        let ground = UIColor(red: 0.027, green: 0.031, blue: 0.047, alpha: 1)
        let lit    = UIColor(red: 1.0, green: 0.965, blue: 0.878, alpha: 1)
        let dark   = UIColor(red: 0.067, green: 0.075, blue: 0.102, alpha: 1)
        let ink    = UIColor(red: 0.94, green: 0.93, blue: 0.90, alpha: 1)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let size = CGSize(width: side, height: side)
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext

            ground.setFill()
            cg.fill(CGRect(origin: .zero, size: size))

            // Stars — fixed positions so the same night always looks the same.
            lit.withAlphaComponent(0.4).setFill()
            for (x, y, r) in starField {
                cg.fillEllipse(in: CGRect(x: x * side - r, y: y * side - r, width: r * 2, height: r * 2))
            }

            // The moon, up and slightly left of centre.
            let radius = side * 0.135
            let centre = CGPoint(x: side * 0.5, y: side * 0.30)
            let disc = CGRect(x: centre.x - radius, y: centre.y - radius,
                              width: radius * 2, height: radius * 2)

            cg.saveGState()
            cg.setShadow(offset: .zero, blur: side * 0.07,
                         color: lit.withAlphaComponent(0.5).cgColor)
            lit.setFill()
            cg.fillEllipse(in: disc.insetBy(dx: radius * 0.12, dy: radius * 0.12))
            cg.restoreGState()

            dark.setFill()
            cg.fillEllipse(in: disc)

            let waxing = fraction < 0.5
            cg.saveGState()
            cg.addEllipse(in: disc)
            cg.clip()
            lit.setFill()
            cg.fill(CGRect(x: waxing ? centre.x : disc.minX, y: disc.minY,
                           width: radius, height: radius * 2))

            let k = abs(cos(2 * Double.pi * fraction))
            let gibbous = fraction > 0.25 && fraction < 0.75
            (gibbous ? lit : dark).setFill()
            cg.fillEllipse(in: CGRect(x: centre.x - radius * k, y: disc.minY,
                                      width: radius * 2 * k, height: radius * 2))
            cg.restoreGState()

            // The caption, in the small spaced type the app uses everywhere.
            let inset = side * 0.11
            let width = side - inset * 2

            let capStyle = NSMutableParagraphStyle()
            capStyle.alignment = .center
            let cap = NSAttributedString(
                string: caption.uppercased(),
                attributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: side * 0.030, weight: .medium),
                    .foregroundColor: ink.withAlphaComponent(0.55),
                    .kern: NSNumber(value: Double(side) * 0.004),
                    .paragraphStyle: capStyle
                ]
            )
            cap.draw(in: CGRect(x: inset, y: side * 0.475, width: width, height: side * 0.07))

            // The line itself. Shrinks a step at a time rather than clipping.
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            let lineStyle = NSMutableParagraphStyle()
            lineStyle.alignment = .center
            lineStyle.lineHeightMultiple = 1.12

            let box = CGRect(x: inset, y: side * 0.545, width: width, height: side * 0.36)
            for step in stride(from: 0.082, through: 0.042, by: -0.006) {
                let pointSize = side * CGFloat(step)
                let text = NSAttributedString(
                    string: trimmed,
                    attributes: [
                        .font: UIFont.systemFont(ofSize: pointSize, weight: .semibold),
                        .foregroundColor: ink,
                        .paragraphStyle: lineStyle
                    ]
                )
                let fitted = text.boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                )
                if fitted.height <= box.height || step <= 0.048 {
                    text.draw(in: CGRect(x: box.minX, y: box.minY,
                                         width: box.width, height: box.height))
                    break
                }
            }
        }
    }

    private static let starField: [(CGFloat, CGFloat, CGFloat)] = [
        (0.08, 0.10, 2.6), (0.22, 0.05, 2.0), (0.41, 0.13, 2.8),
        (0.63, 0.07, 2.2), (0.79, 0.15, 2.7), (0.92, 0.09, 2.0),
        (0.12, 0.27, 1.9), (0.87, 0.31, 2.4), (0.05, 0.42, 2.1),
        (0.95, 0.46, 1.8), (0.17, 0.52, 2.2), (0.83, 0.58, 1.9),
        (0.07, 0.71, 2.3), (0.93, 0.76, 2.0), (0.31, 0.93, 2.1),
        (0.68, 0.90, 2.5), (0.49, 0.97, 1.8), (0.15, 0.86, 2.0)
    ]

    /// Writes a card somewhere a notification can reach it.
    static func cardFile(fraction: Double, line: String, caption: String, name: String) -> URL? {
        guard let data = card(fraction: fraction, line: line, caption: caption).pngData() else { return nil }
        return write(data, name: name)
    }

    /// Writes tonight's moon somewhere a notification can reach it.
    static func temporaryFile(fraction: Double, name: String) -> URL? {
        guard let data = render(fraction: fraction).pngData() else { return nil }
        return write(data, name: name)
    }

    private static func write(_ data: Data, name: String) -> URL? {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("moon-attachments", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let url = folder.appendingPathComponent("\(name).png")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
