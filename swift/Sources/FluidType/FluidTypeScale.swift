import CoreGraphics
import Foundation

/// Line-height anchors shared by every port. See `spec/line-height.tsv`.
private let looseAt: CGFloat = 16
private let tightAt: CGFloat = 48
private let loose: CGFloat = 1.5
private let tight: CGFloat = 1.1

/// A viewport-driven type scale.
///
/// The root size interpolates linearly from ``minRootSize`` to ``maxRootSize``
/// as the container grows from ``minWidth`` to ``maxWidth``, and holds flat
/// outside that range. Every other size is derived from the root by powers of
/// ``ratio``, which is what makes a single number — the container width — move
/// an entire type hierarchy in step.
///
/// ```swift
/// let scale = FluidTypeScale(
///     minWidth: 360, maxWidth: 1024,
///     minRootSize: 15, maxRootSize: 22
/// )
/// let body = scale.size(.body, at: 768)
/// ```
public struct FluidTypeScale: Equatable, Hashable, Sendable {
    /// The width at or below which the root size stays at ``minRootSize``, in
    /// points.
    public let minWidth: CGFloat

    /// The width at or above which the root size stays at ``maxRootSize``, in
    /// points.
    public let maxWidth: CGFloat

    /// The root size at ``minWidth``, in points.
    public let minRootSize: CGFloat

    /// The root size at ``maxWidth``, in points.
    public let maxRootSize: CGFloat

    /// The geometric ratio between adjacent steps of the scale.
    ///
    /// 1.2 (a major second) is the default because it stays readable on a
    /// phone; 1.25 and 1.333 open up nicely on larger screens but turn
    /// ``FluidTypeRole/h1`` into a billboard at 360pt.
    public let ratio: CGFloat

    /// Creates a scale.
    ///
    /// Traps on an inverted width range or a non-positive size. A scale built
    /// from bad numbers produces type that is plausible-looking and wrong,
    /// which is harder to find than a crash at launch. A scale where
    /// `minWidth == maxWidth` is legal and behaves as a single breakpoint.
    public init(
        minWidth: CGFloat,
        maxWidth: CGFloat,
        minRootSize: CGFloat,
        maxRootSize: CGFloat,
        ratio: CGFloat = 1.2
    ) {
        precondition(
            minWidth.isFinite && maxWidth.isFinite,
            "minWidth and maxWidth must be finite"
        )
        precondition(
            minWidth <= maxWidth,
            "minWidth (\(minWidth)) must be <= maxWidth (\(maxWidth))"
        )
        precondition(
            minRootSize > 0 && maxRootSize > 0,
            "root sizes must be positive"
        )
        precondition(ratio > 0, "ratio must be positive")

        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minRootSize = minRootSize
        self.maxRootSize = maxRootSize
        self.ratio = ratio
    }

    /// The scale from the original SCSS: 400–800pt wide, 12–24pt root.
    ///
    /// Useful as a starting point, and the scale the conformance fixtures in
    /// `spec/` are generated from.
    public static let reference = FluidTypeScale(
        minWidth: 400,
        maxWidth: 800,
        minRootSize: 12,
        maxRootSize: 24
    )

    /// A scale tuned for phone-to-tablet layouts: 360–768pt, 14–18pt root.
    public static let mobile = FluidTypeScale(
        minWidth: 360,
        maxWidth: 768,
        minRootSize: 14,
        maxRootSize: 18
    )

    /// The root size for `width`, clamped at both ends.
    ///
    /// The upper plateau is tested first on purpose: when ``minWidth`` equals
    /// ``maxWidth`` the scale degenerates to a single breakpoint, and this
    /// ordering makes it step up to ``maxRootSize`` there rather than down. It
    /// also guarantees the division below never sees a zero denominator.
    public func rootSize(at width: CGFloat) -> CGFloat {
        if width >= maxWidth { return maxRootSize }
        if width <= minWidth { return minRootSize }
        let t = (width - minWidth) / (maxWidth - minWidth)
        return minRootSize + (maxRootSize - minRootSize) * t
    }

    /// `multiplier` times the root size at `width` — the direct analogue of a
    /// CSS `rem` value. Handy for padding and spacing, not just type.
    public func rem(_ multiplier: CGFloat, at width: CGFloat) -> CGFloat {
        rootSize(at: width) * multiplier
    }

    /// The size at `step` on the modular scale, at `width`.
    ///
    /// Step 0 is the root size; positive steps grow by ``ratio``, negative
    /// steps shrink by it. Steps need not be whole numbers.
    public func size(step: Double, at width: CGFloat) -> CGFloat {
        rootSize(at: width) * CGFloat(pow(Double(ratio), step))
    }

    /// The size for a semantic `role`, at `width`.
    public func size(_ role: FluidTypeRole, at width: CGFloat) -> CGFloat {
        size(step: Double(role.step), at: width)
    }

    /// A line-height *multiplier* for `fontSize`.
    ///
    /// Leading that works for body copy is too airy for a display heading, so
    /// this tightens from 1.5 to 1.1 as type grows from 16 to 48 points.
    ///
    /// SwiftUI's `lineSpacing(_:)` takes the *extra* space between lines
    /// rather than a multiplier, so prefer
    /// ``FluidType/lineSpacing(_:)-swift.method`` over doing that arithmetic
    /// at the call site.
    public func lineHeight(forFontSize fontSize: CGFloat) -> CGFloat {
        let t = min(max((fontSize - looseAt) / (tightAt - looseAt), 0), 1)
        return loose + (tight - loose) * t
    }

    /// Resolves this scale against a single `width`.
    ///
    /// The result caches the root size, which is the only part of the
    /// computation that depends on the container, so a view that asks for a
    /// dozen sizes does the interpolation once.
    public func resolved(at width: CGFloat) -> FluidType {
        FluidType(scale: self, width: width)
    }

    /// A copy of this scale with the given values replaced.
    public func with(
        minWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        minRootSize: CGFloat? = nil,
        maxRootSize: CGFloat? = nil,
        ratio: CGFloat? = nil
    ) -> FluidTypeScale {
        FluidTypeScale(
            minWidth: minWidth ?? self.minWidth,
            maxWidth: maxWidth ?? self.maxWidth,
            minRootSize: minRootSize ?? self.minRootSize,
            maxRootSize: maxRootSize ?? self.maxRootSize,
            ratio: ratio ?? self.ratio
        )
    }
}

extension FluidTypeScale: CustomStringConvertible {
    public var description: String {
        "FluidTypeScale(\(minWidth)..\(maxWidth)pt -> "
            + "\(minRootSize)..\(maxRootSize)pt, ratio \(ratio))"
    }
}

/// A ``FluidTypeScale`` resolved against one container width.
///
/// This is what views read. ``FluidTypeReader`` puts one in the environment
/// and updates it when the container resizes, so `@Environment(\.fluidType)`
/// is a lookup rather than a calculation.
public struct FluidType: Equatable, Hashable, Sendable {
    /// The scale this was resolved from.
    public let scale: FluidTypeScale

    /// The width it was resolved at, in points.
    public let width: CGFloat

    /// The root size at ``width`` — the `1rem` of this scale.
    public let rootSize: CGFloat

    /// Resolves `scale` at `width`.
    public init(scale: FluidTypeScale, width: CGFloat) {
        self.scale = scale
        self.width = width
        self.rootSize = scale.rootSize(at: width)
    }

    /// `multiplier` rem, in points.
    public func rem(_ multiplier: CGFloat) -> CGFloat {
        rootSize * multiplier
    }

    /// The size at `step` on the modular scale, in points.
    public func size(step: Double) -> CGFloat {
        rootSize * CGFloat(pow(Double(scale.ratio), step))
    }

    /// The size for a semantic `role`, in points.
    public func size(_ role: FluidTypeRole) -> CGFloat {
        size(step: Double(role.step))
    }

    /// A line-height multiplier for `fontSize`; see
    /// ``FluidTypeScale/lineHeight(forFontSize:)``.
    public func lineHeight(forFontSize fontSize: CGFloat) -> CGFloat {
        scale.lineHeight(forFontSize: fontSize)
    }

    /// The ``FluidTypeRole/body`` size, in points.
    public var body: CGFloat { size(.body) }

    /// The extra space to put between lines of `role`, in points.
    ///
    /// SwiftUI's `lineSpacing(_:)` adds this on top of the font's own line
    /// height rather than replacing it, so it is the multiplier minus one,
    /// times the size. This is the single most common place hand-rolled fluid
    /// type goes wrong on Apple platforms.
    public func lineSpacing(_ role: FluidTypeRole) -> CGFloat {
        let fontSize = size(role)
        return fontSize * (lineHeight(forFontSize: fontSize) - 1)
    }
}
