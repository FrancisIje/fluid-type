#if canImport(SwiftUI)
import FluidType
import SwiftUI

/// A type specimen that responds to the size of its container.
///
/// Resize the window, rotate the device, or drag a split-view divider, and
/// every size on the page moves together. The readout at the bottom prints the
/// width and the root size so the interpolation is visible rather than merely
/// felt.
///
/// To run it, drop this file into an app target and make it the root view:
///
/// ```swift
/// @main
/// struct SpecimenApp: App {
///     var body: some Scene {
///         WindowGroup { FluidTypeSpecimen() }
///     }
/// }
/// ```
public struct FluidTypeSpecimen: View {
    // 360->1024pt is a sensible phone-to-tablet range; 15->22pt keeps body
    // copy comfortable at both ends.
    private static let scale = FluidTypeScale(
        minWidth: 360,
        maxWidth: 1024,
        minRootSize: 15,
        maxRootSize: 22
    )

    @State private var ratio: CGFloat = 1.2

    public init() {}

    public var body: some View {
        FluidTypeReader(Self.scale.with(ratio: ratio)) { fluid in
            ScrollView {
                VStack(alignment: .leading, spacing: fluid.rem(0.5)) {
                    Text("Fluid type")
                        .fluidText(.h3, weight: .bold)
                    Text("One number drives the hierarchy. Resize the window.")
                        .fluidText(.body)
                        .foregroundStyle(.secondary)

                    Divider().padding(.vertical, fluid.rem(0.5))

                    ForEach(FluidTypeRole.allCases.reversed(), id: \.self) { role in
                        specimenRow(role, fluid: fluid)
                    }

                    ratioControl(fluid: fluid)
                    readout(fluid: fluid)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(fluid.rem(1.5))
            }
        }
    }

    private func specimenRow(_ role: FluidTypeRole, fluid: FluidType) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: fluid.rem(0.5)) {
            Text(String(describing: role).uppercased())
                .fluidText(.caption)
                .foregroundStyle(.tertiary)
                .frame(width: fluid.rem(3.5), alignment: .leading)

            Text("Grumpy wizards make toxic brew")
                .fluidText(role)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(fluid.size(role), specifier: "%.1f")pt")
                .fluidText(.caption)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
    }

    private func ratioControl(fluid: FluidType) -> some View {
        VStack(alignment: .leading, spacing: fluid.rem(0.25)) {
            Text("Ratio \(ratio, specifier: "%.3f")")
                .fluidText(.small, weight: .medium)
            #if !os(tvOS) && !os(watchOS)
                Slider(value: $ratio, in: 1.05...1.4)
            #endif
        }
        .padding(.top, fluid.rem(1))
    }

    private func readout(fluid: FluidType) -> some View {
        // Built with String(format:) rather than concatenated interpolations:
        // adding up several LocalizedStringKey fragments with + is the kind of
        // expression that sends the type checker away for a very long time.
        let text = String(
            format: "viewport %.0fpt  ->  root %.2fpt  (clamped %.0f-%.0fpt)",
            fluid.width,
            fluid.rootSize,
            fluid.scale.minWidth,
            fluid.scale.maxWidth
        )
        return Text(verbatim: text)
            .fluidText(.small)
            .foregroundStyle(.secondary)
            .padding(fluid.rem(0.75))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                .quaternary,
                in: RoundedRectangle(cornerRadius: fluid.rem(0.5))
            )
    }
}

#if DEBUG
    #Preview {
        FluidTypeSpecimen()
    }
#endif
#endif
