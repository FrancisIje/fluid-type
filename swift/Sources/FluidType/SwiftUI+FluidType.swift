#if canImport(SwiftUI)
import SwiftUI

// MARK: - Environment

private struct FluidTypeEnvironmentKey: EnvironmentKey {
    static let defaultValue: FluidType? = nil
}

extension EnvironmentValues {
    /// The resolved scale from the nearest ``FluidTypeReader`` or
    /// ``SwiftUICore/View/fluidType(_:at:)``, or `nil` if there is none.
    ///
    /// Read this from a view that must work either way — a component shipped
    /// to other teams, for instance. Most views want ``fluidType``.
    public var fluidTypeIfPresent: FluidType? {
        get { self[FluidTypeEnvironmentKey.self] }
        set { self[FluidTypeEnvironmentKey.self] = newValue }
    }

    /// The resolved scale from the nearest provider.
    ///
    /// Falls back to ``FluidTypeScale/mobile`` at its own
    /// ``FluidTypeScale/minWidth`` when no provider is present, and trips an
    /// assertion in debug builds while it does so. Type that is silently a
    /// little wrong everywhere is harder to notice than type that is loudly
    /// wrong in development, which is the whole reason for the assertion.
    public var fluidType: FluidType {
        guard let resolved = fluidTypeIfPresent else {
            assertionFailure(
                """
                No fluid type scale in the environment. Wrap the view — or at \
                least the subtree that reads fluid type — in a \
                FluidTypeReader, or apply .fluidType(scale, at: width) when \
                you already know the width.
                """
            )
            return FluidTypeScale.mobile.resolved(at: FluidTypeScale.mobile.minWidth)
        }
        return resolved
    }
}

// MARK: - Providers

/// Resolves a scale against its own container and hands it to `content`.
///
/// This is the usual way in. Put it at the root of a screen:
///
/// ```swift
/// FluidTypeReader(.mobile) { fluid in
///     VStack(alignment: .leading, spacing: fluid.rem(0.5)) {
///         Text("Title").fluidText(.h1)
///         Text("Body copy").fluidText(.body)
///     }
/// }
/// ```
///
/// The resolved value also lands in the environment, so views further down can
/// read `@Environment(\.fluidType)` instead of threading it through.
///
/// It is built on `GeometryReader`, which means it claims all the space
/// offered to it and aligns `content` to the top leading corner. That is what
/// you want at the root of a screen and not what you want halfway down a
/// `VStack`; for that case the width is usually already known, so use
/// ``SwiftUICore/View/fluidType(_:at:)``.
public struct FluidTypeReader<Content: View>: View {
    private let scale: FluidTypeScale
    private let content: (FluidType) -> Content

    /// Creates a reader that resolves `scale` against its container.
    public init(
        _ scale: FluidTypeScale = .mobile,
        @ViewBuilder content: @escaping (FluidType) -> Content
    ) {
        self.scale = scale
        self.content = content
    }

    public var body: some View {
        GeometryReader { proxy in
            let resolved = scale.resolved(at: proxy.size.width)
            content(resolved)
                .environment(\.fluidTypeIfPresent, resolved)
        }
    }
}

extension View {
    /// Puts `scale`, resolved at `width`, into the environment for this
    /// subtree.
    ///
    /// Use this when the width is already known — inside a `List` row whose
    /// width you measured once, or on a platform where you track the window
    /// size yourself — and you would rather not introduce a `GeometryReader`.
    public func fluidType(
        _ scale: FluidTypeScale,
        at width: CGFloat
    ) -> some View {
        environment(\.fluidTypeIfPresent, scale.resolved(at: width))
    }

    /// Puts an already resolved scale into the environment for this subtree.
    public func fluidType(_ resolved: FluidType) -> some View {
        environment(\.fluidTypeIfPresent, resolved)
    }
}

// MARK: - Fonts

extension FluidType {
    /// A system font at the size for `role`.
    ///
    /// `Font.system(size:)` is a fixed size and so does not grow with the
    /// reader's Dynamic Type setting. That is a deliberate trade: this scale
    /// already responds to the container, and stacking two independent
    /// scaling systems tends to overflow layouts. If you need both, use
    /// ``font(_:name:relativeTo:)`` with a custom family, which does scale.
    public func font(
        _ role: FluidTypeRole,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> Font {
        .system(size: size(role), weight: weight, design: design)
    }

    /// A custom font at the size for `role`, scaling with Dynamic Type
    /// relative to `textStyle`.
    public func font(
        _ role: FluidTypeRole,
        name: String,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        .custom(name, size: size(role), relativeTo: textStyle)
    }
}

extension View {
    /// Applies the font and line spacing for `role` from the environment's
    /// resolved scale.
    ///
    /// ```swift
    /// Text("Grumpy wizards").fluidText(.h2, weight: .semibold)
    /// ```
    public func fluidText(
        _ role: FluidTypeRole,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        modifier(FluidTextModifier(role: role, weight: weight, design: design))
    }
}

private struct FluidTextModifier: ViewModifier {
    @Environment(\.fluidType) private var fluid

    let role: FluidTypeRole
    let weight: Font.Weight
    let design: Font.Design

    func body(content: Content) -> some View {
        content
            .font(fluid.font(role, weight: weight, design: design))
            .lineSpacing(fluid.lineSpacing(role))
    }
}
#endif
