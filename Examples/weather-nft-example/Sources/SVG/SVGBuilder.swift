import Foundation

/// Low-level SVG element builder for creating SVG markup.
///
/// Provides pure Swift methods for generating SVG elements as strings.
/// All methods are static and return valid SVG markup.
public enum SVGBuilder {
    // MARK: - Document

    /// Creates a complete SVG document.
    ///
    /// - Parameters:
    ///   - width: Canvas width in pixels.
    ///   - height: Canvas height in pixels.
    ///   - content: The SVG content (elements) to include.
    /// - Returns: Complete SVG document string.
    public static func document(
        width: Int,
        height: Int,
        content: String
    ) -> String {
        """
        <svg xmlns="http://www.w3.org/2000/svg" width="\(width)" height="\(height)" viewBox="0 0 \(width) \(height)">
        \(content)
        </svg>
        """
    }

    // MARK: - Definitions

    /// Creates a defs section for reusable elements.
    ///
    /// - Parameter content: The definitions content.
    /// - Returns: SVG defs element.
    public static func defs(_ content: String) -> String {
        """
        <defs>
        \(content)
        </defs>
        """
    }

    /// Creates a linear gradient definition.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the gradient.
    ///   - x1: Start x position (percentage).
    ///   - y1: Start y position (percentage).
    ///   - x2: End x position (percentage).
    ///   - y2: End y position (percentage).
    ///   - stops: Array of (offset, color) tuples.
    /// - Returns: SVG linearGradient element.
    public static func linearGradient(
        id: String,
        x1: String = "0%",
        y1: String = "0%",
        x2: String = "0%",
        y2: String = "100%",
        stops: [(offset: String, color: String)]
    ) -> String {
        let stopElements = stops.map { stop in
            "<stop offset=\"\(stop.offset)\" stop-color=\"\(stop.color)\"/>"
        }.joined(separator: "\n")

        return """
        <linearGradient id="\(id)" x1="\(x1)" y1="\(y1)" x2="\(x2)" y2="\(y2)">
        \(stopElements)
        </linearGradient>
        """
    }

    /// Creates a radial gradient definition.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the gradient.
    ///   - cx: Center x position (percentage).
    ///   - cy: Center y position (percentage).
    ///   - r: Radius (percentage).
    ///   - stops: Array of (offset, color) tuples.
    /// - Returns: SVG radialGradient element.
    public static func radialGradient(
        id: String,
        cx: String = "50%",
        cy: String = "50%",
        r: String = "50%",
        stops: [(offset: String, color: String)]
    ) -> String {
        let stopElements = stops.map { stop in
            "<stop offset=\"\(stop.offset)\" stop-color=\"\(stop.color)\"/>"
        }.joined(separator: "\n")

        return """
        <radialGradient id="\(id)" cx="\(cx)" cy="\(cy)" r="\(r)">
        \(stopElements)
        </radialGradient>
        """
    }

    // MARK: - Shapes

    /// Creates a rectangle element.
    ///
    /// - Parameters:
    ///   - x: X position.
    ///   - y: Y position.
    ///   - width: Rectangle width.
    ///   - height: Rectangle height.
    ///   - fill: Fill color or gradient reference.
    ///   - rx: Corner radius x.
    ///   - ry: Corner radius y.
    ///   - opacity: Fill opacity (0-1).
    /// - Returns: SVG rect element.
    public static func rect(
        x: Double = 0,
        y: Double = 0,
        width: Double,
        height: Double,
        fill: String,
        rx: Double? = nil,
        ry: Double? = nil,
        opacity: Double? = nil
    ) -> String {
        var attrs = "x=\"\(x)\" y=\"\(y)\" width=\"\(width)\" height=\"\(height)\" fill=\"\(fill)\""

        if let rx { attrs += " rx=\"\(rx)\"" }
        if let ry { attrs += " ry=\"\(ry)\"" }
        if let opacity { attrs += " opacity=\"\(opacity)\"" }

        return "<rect \(attrs)/>"
    }

    /// Creates a circle element.
    ///
    /// - Parameters:
    ///   - cx: Center x position.
    ///   - cy: Center y position.
    ///   - r: Radius.
    ///   - fill: Fill color.
    ///   - stroke: Stroke color.
    ///   - strokeWidth: Stroke width.
    ///   - opacity: Fill opacity (0-1).
    /// - Returns: SVG circle element.
    public static func circle(
        cx: Double,
        cy: Double,
        r: Double,
        fill: String,
        stroke: String? = nil,
        strokeWidth: Double? = nil,
        opacity: Double? = nil
    ) -> String {
        var attrs = "cx=\"\(cx)\" cy=\"\(cy)\" r=\"\(r)\" fill=\"\(fill)\""

        if let stroke { attrs += " stroke=\"\(stroke)\"" }
        if let strokeWidth { attrs += " stroke-width=\"\(strokeWidth)\"" }
        if let opacity { attrs += " opacity=\"\(opacity)\"" }

        return "<circle \(attrs)/>"
    }

    /// Creates an ellipse element.
    ///
    /// - Parameters:
    ///   - cx: Center x position.
    ///   - cy: Center y position.
    ///   - rx: X radius.
    ///   - ry: Y radius.
    ///   - fill: Fill color.
    ///   - opacity: Fill opacity (0-1).
    /// - Returns: SVG ellipse element.
    public static func ellipse(
        cx: Double,
        cy: Double,
        rx: Double,
        ry: Double,
        fill: String,
        opacity: Double? = nil
    ) -> String {
        var attrs = "cx=\"\(cx)\" cy=\"\(cy)\" rx=\"\(rx)\" ry=\"\(ry)\" fill=\"\(fill)\""

        if let opacity { attrs += " opacity=\"\(opacity)\"" }

        return "<ellipse \(attrs)/>"
    }

    /// Creates a line element.
    ///
    /// - Parameters:
    ///   - x1: Start x position.
    ///   - y1: Start y position.
    ///   - x2: End x position.
    ///   - y2: End y position.
    ///   - stroke: Stroke color.
    ///   - strokeWidth: Stroke width.
    ///   - strokeLinecap: Line cap style (butt, round, square).
    /// - Returns: SVG line element.
    public static func line(
        x1: Double,
        y1: Double,
        x2: Double,
        y2: Double,
        stroke: String,
        strokeWidth: Double = 1,
        strokeLinecap: String? = nil
    ) -> String {
        var attrs = "x1=\"\(x1)\" y1=\"\(y1)\" x2=\"\(x2)\" y2=\"\(y2)\" stroke=\"\(stroke)\" stroke-width=\"\(strokeWidth)\""

        if let strokeLinecap { attrs += " stroke-linecap=\"\(strokeLinecap)\"" }

        return "<line \(attrs)/>"
    }

    /// Creates a path element.
    ///
    /// - Parameters:
    ///   - d: Path data (SVG path commands).
    ///   - fill: Fill color.
    ///   - stroke: Stroke color.
    ///   - strokeWidth: Stroke width.
    ///   - opacity: Fill opacity (0-1).
    /// - Returns: SVG path element.
    public static func path(
        d: String,
        fill: String = "none",
        stroke: String? = nil,
        strokeWidth: Double? = nil,
        opacity: Double? = nil
    ) -> String {
        var attrs = "d=\"\(d)\" fill=\"\(fill)\""

        if let stroke { attrs += " stroke=\"\(stroke)\"" }
        if let strokeWidth { attrs += " stroke-width=\"\(strokeWidth)\"" }
        if let opacity { attrs += " opacity=\"\(opacity)\"" }

        return "<path \(attrs)/>"
    }

    // MARK: - Text

    /// Creates a text element.
    ///
    /// - Parameters:
    ///   - content: The text content.
    ///   - x: X position.
    ///   - y: Y position.
    ///   - fontSize: Font size in pixels.
    ///   - fill: Text color.
    ///   - fontWeight: Font weight (normal, bold, 100-900).
    ///   - fontFamily: Font family.
    ///   - textAnchor: Text anchor (start, middle, end).
    ///   - dominantBaseline: Baseline alignment.
    /// - Returns: SVG text element.
    public static func text(
        _ content: String,
        x: Double,
        y: Double,
        fontSize: Double,
        fill: String,
        fontWeight: String? = nil,
        fontFamily: String = "system-ui, -apple-system, sans-serif",
        textAnchor: String = "middle",
        dominantBaseline: String? = nil
    ) -> String {
        var attrs = "x=\"\(x)\" y=\"\(y)\" font-size=\"\(fontSize)\" fill=\"\(fill)\" font-family=\"\(fontFamily)\" text-anchor=\"\(textAnchor)\""

        if let fontWeight { attrs += " font-weight=\"\(fontWeight)\"" }
        if let dominantBaseline { attrs += " dominant-baseline=\"\(dominantBaseline)\"" }

        let escapedContent = content
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        return "<text \(attrs)>\(escapedContent)</text>"
    }

    // MARK: - Grouping

    /// Creates a group element.
    ///
    /// - Parameters:
    ///   - transform: Optional transform attribute.
    ///   - opacity: Group opacity (0-1).
    ///   - content: The grouped content.
    /// - Returns: SVG g element.
    public static func group(
        transform: String? = nil,
        opacity: Double? = nil,
        content: String
    ) -> String {
        var attrs = ""

        if let transform { attrs += " transform=\"\(transform)\"" }
        if let opacity { attrs += " opacity=\"\(opacity)\"" }

        if attrs.isEmpty {
            return "<g>\n\(content)\n</g>"
        } else {
            return "<g\(attrs)>\n\(content)\n</g>"
        }
    }

    /// Creates a translate transform string.
    ///
    /// - Parameters:
    ///   - x: X translation.
    ///   - y: Y translation.
    /// - Returns: Transform string.
    public static func translate(x: Double, y: Double) -> String {
        "translate(\(x), \(y))"
    }

    /// Creates a scale transform string.
    ///
    /// - Parameters:
    ///   - x: X scale factor.
    ///   - y: Y scale factor.
    /// - Returns: Transform string.
    public static func scale(x: Double, y: Double? = nil) -> String {
        if let y {
            return "scale(\(x), \(y))"
        } else {
            return "scale(\(x))"
        }
    }

    /// Creates a rotate transform string.
    ///
    /// - Parameters:
    ///   - angle: Rotation angle in degrees.
    ///   - cx: Optional center x for rotation.
    ///   - cy: Optional center y for rotation.
    /// - Returns: Transform string.
    public static func rotate(angle: Double, cx: Double? = nil, cy: Double? = nil) -> String {
        if let cx, let cy {
            return "rotate(\(angle), \(cx), \(cy))"
        } else {
            return "rotate(\(angle))"
        }
    }
}
