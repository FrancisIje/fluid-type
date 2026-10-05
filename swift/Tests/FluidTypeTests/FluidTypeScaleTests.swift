import CoreGraphics
import XCTest

@testable import FluidType

final class FluidTypeScaleTests: XCTestCase {
    private let scale = FluidTypeScale.reference
    private let tolerance: CGFloat = 1e-12

    // MARK: - rootSize

    func testHoldsAtMinRootSizeBelowAndAtMinWidth() {
        XCTAssertEqual(scale.rootSize(at: 0), 12)
        XCTAssertEqual(scale.rootSize(at: 320), 12)
        XCTAssertEqual(scale.rootSize(at: 400), 12)
    }

    func testHoldsAtMaxRootSizeAtAndAboveMaxWidth() {
        XCTAssertEqual(scale.rootSize(at: 800), 24)
        XCTAssertEqual(scale.rootSize(at: 1280), 24)
        XCTAssertEqual(scale.rootSize(at: .greatestFiniteMagnitude), 24)
    }

    func testInterpolatesLinearlyInBetween() {
        XCTAssertEqual(scale.rootSize(at: 500), 15, accuracy: tolerance)
        XCTAssertEqual(scale.rootSize(at: 600), 18, accuracy: tolerance)
        XCTAssertEqual(scale.rootSize(at: 700), 21, accuracy: tolerance)
    }

    func testIsContinuousAtTheBreakpoints() {
        XCTAssertEqual(scale.rootSize(at: 400.0001), 12, accuracy: 1e-5)
        XCTAssertEqual(scale.rootSize(at: 799.9999), 24, accuracy: 1e-5)
    }

    func testIsMonotonicallyNonDecreasing() {
        var previous = -CGFloat.greatestFiniteMagnitude
        var width: CGFloat = 0
        while width <= 1200 {
            let size = scale.rootSize(at: width)
            XCTAssertGreaterThanOrEqual(size, previous, "dipped at width \(width)")
            previous = size
            width += 0.5
        }
    }

    func testAZeroWidthRangeIsAHardBreakpoint() {
        let step = FluidTypeScale(
            minWidth: 600,
            maxWidth: 600,
            minRootSize: 12,
            maxRootSize: 24
        )
        XCTAssertEqual(step.rootSize(at: 599), 12)
        XCTAssertEqual(step.rootSize(at: 600), 24)
        XCTAssertEqual(step.rootSize(at: 601), 24)
        XCTAssertFalse(step.rootSize(at: 600).isNaN)
    }

    func testADescendingScaleShrinksTypeAsTheContainerGrows() {
        // Unusual but legal: some designs want tighter type on wide screens.
        let descending = FluidTypeScale(
            minWidth: 400,
            maxWidth: 800,
            minRootSize: 20,
            maxRootSize: 16
        )
        XCTAssertEqual(descending.rootSize(at: 400), 20)
        XCTAssertEqual(descending.rootSize(at: 600), 18, accuracy: tolerance)
        XCTAssertEqual(descending.rootSize(at: 800), 16)
    }

    // MARK: - The modular scale

    func testStepZeroIsTheRootSize() {
        XCTAssertEqual(scale.size(step: 0, at: 600), 18, accuracy: tolerance)
    }

    func testEachStepMultipliesByTheRatio() {
        let root = scale.rootSize(at: 600)
        XCTAssertEqual(scale.size(step: 1, at: 600), root * 1.2, accuracy: tolerance)
        XCTAssertEqual(
            scale.size(step: 2, at: 600),
            root * 1.2 * 1.2,
            accuracy: tolerance
        )
        XCTAssertEqual(scale.size(step: -1, at: 600), root / 1.2, accuracy: tolerance)
    }

    func testAcceptsFractionalSteps() {
        let half = scale.size(step: 0.5, at: 600)
        XCTAssertGreaterThan(half, scale.size(step: 0, at: 600))
        XCTAssertLessThan(half, scale.size(step: 1, at: 600))
    }

    func testRolesSitWhereTheSpecSaysTheyDo() {
        XCTAssertEqual(FluidTypeRole.caption.step, -2)
        XCTAssertEqual(FluidTypeRole.small.step, -1)
        XCTAssertEqual(FluidTypeRole.body.step, 0)
        XCTAssertEqual(FluidTypeRole.h1.step, 6)
        XCTAssertEqual(
            scale.size(.h1, at: 600),
            scale.size(step: 6, at: 600),
            accuracy: tolerance
        )
    }

    func testRolesAreOrderedSmallestToLargest() {
        let sizes = FluidTypeRole.allCases.map { scale.size($0, at: 600) }
        for index in 1..<sizes.count {
            XCTAssertGreaterThan(sizes[index], sizes[index - 1])
        }
    }

    func testRemMatchesAStepOfTheSameMultiplier() {
        XCTAssertEqual(scale.rem(2, at: 600), 36, accuracy: tolerance)
        XCTAssertEqual(scale.rem(0.5, at: 800), 12, accuracy: tolerance)
    }

    // MARK: - Line height

    func testLineHeightIsLooseForSmallTypeAndTightForDisplayType() {
        XCTAssertEqual(scale.lineHeight(forFontSize: 8), 1.5, accuracy: tolerance)
        XCTAssertEqual(scale.lineHeight(forFontSize: 16), 1.5, accuracy: tolerance)
        XCTAssertEqual(scale.lineHeight(forFontSize: 48), 1.1, accuracy: tolerance)
        XCTAssertEqual(scale.lineHeight(forFontSize: 96), 1.1, accuracy: tolerance)
    }

    func testLineHeightTightensMonotonically() {
        var previous = CGFloat.greatestFiniteMagnitude
        var size: CGFloat = 16
        while size <= 48 {
            let height = scale.lineHeight(forFontSize: size)
            XCTAssertLessThanOrEqual(height, previous, "loosened at size \(size)")
            previous = height
            size += 0.25
        }
    }

    func testLineHeightIsTheMidpointAtTheMidpoint() {
        XCTAssertEqual(scale.lineHeight(forFontSize: 32), 1.3, accuracy: tolerance)
    }

    func testLineSpacingIsExtraSpaceNotTheWholeLineHeight() {
        let fluid = scale.resolved(at: 800)
        // 24pt body sits a quarter of the way from 16 to 48, multiplier 1.4.
        XCTAssertEqual(fluid.size(.body), 24, accuracy: tolerance)
        XCTAssertEqual(fluid.lineSpacing(.body), 24 * 0.4, accuracy: tolerance)
        XCTAssertLessThan(fluid.lineSpacing(.body), fluid.size(.body))
    }

    // MARK: - Resolving

    func testResolvedCachesTheRootSize() {
        let fluid = scale.resolved(at: 600)
        XCTAssertEqual(fluid.rootSize, 18, accuracy: tolerance)
        XCTAssertEqual(fluid.width, 600)
        XCTAssertEqual(fluid.body, 18, accuracy: tolerance)
        XCTAssertEqual(fluid.scale, scale)
    }

    func testResolvedAgreesWithTheUnresolvedScale() {
        let fluid = scale.resolved(at: 537)
        for role in FluidTypeRole.allCases {
            XCTAssertEqual(
                fluid.size(role),
                scale.size(role, at: 537),
                accuracy: tolerance
            )
        }
        XCTAssertEqual(fluid.rem(3), scale.rem(3, at: 537), accuracy: tolerance)
        XCTAssertEqual(
            fluid.size(step: 2.5),
            scale.size(step: 2.5, at: 537),
            accuracy: tolerance
        )
        XCTAssertEqual(
            fluid.lineHeight(forFontSize: 20),
            scale.lineHeight(forFontSize: 20)
        )
    }

    // MARK: - Value semantics

    func testEqualScalesCompareAndHashEqual() {
        let other = FluidTypeScale(
            minWidth: 400,
            maxWidth: 800,
            minRootSize: 12,
            maxRootSize: 24
        )
        XCTAssertEqual(other, FluidTypeScale.reference)
        XCTAssertEqual(other.hashValue, FluidTypeScale.reference.hashValue)
    }

    func testADifferentRatioIsADifferentScale() {
        XCTAssertNotEqual(scale.with(ratio: 1.25), scale)
    }

    func testWithReplacesOnlyWhatItIsGiven() {
        let wider = scale.with(maxWidth: 1200)
        XCTAssertEqual(wider.maxWidth, 1200)
        XCTAssertEqual(wider.minWidth, scale.minWidth)
        XCTAssertEqual(wider.ratio, scale.ratio)
    }

    func testResolvedValuesDifferByWidth() {
        XCTAssertNotEqual(scale.resolved(at: 600), scale.resolved(at: 601))
        XCTAssertEqual(scale.resolved(at: 600), scale.resolved(at: 600))
    }

    func testDescriptionIsReadable() {
        XCTAssertTrue(FluidTypeScale.reference.description.contains("400.0..800.0"))
    }

    func testDefaultRatioIsAMajorSecond() {
        XCTAssertEqual(
            FluidTypeScale(
                minWidth: 400,
                maxWidth: 800,
                minRootSize: 12,
                maxRootSize: 24
            ).ratio,
            1.2
        )
    }
}
