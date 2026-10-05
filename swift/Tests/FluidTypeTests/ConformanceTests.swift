import CoreGraphics
import Foundation
import XCTest

@testable import FluidType

/// Asserts this port against the fixtures in `spec/`, which are shared with
/// the Flutter, React Native and Compose ports. See `spec/README.md`.
final class ConformanceTests: XCTestCase {
    private let scale = FluidTypeScale.reference
    private let tolerance: CGFloat = 1e-9

    func testRootSizeFixture() throws {
        let rows = try fixture("root-size.tsv")
        XCTAssertFalse(rows.isEmpty, "fixture is empty")
        for row in rows {
            let width = try value(row, 0)
            let expected = try value(row, 1)
            XCTAssertEqual(
                scale.rootSize(at: width),
                expected,
                accuracy: tolerance,
                "rootSize(at: \(width))"
            )
        }
    }

    func testScaleStepsFixture() throws {
        let rows = try fixture("scale-steps.tsv")
        XCTAssertFalse(rows.isEmpty, "fixture is empty")
        for row in rows {
            let width = try value(row, 0)
            let step = try value(row, 1)
            let expected = try value(row, 2)
            XCTAssertEqual(
                scale.size(step: Double(step), at: width),
                expected,
                accuracy: tolerance,
                "size(step: \(step), at: \(width))"
            )
        }
    }

    func testLineHeightFixture() throws {
        let rows = try fixture("line-height.tsv")
        XCTAssertFalse(rows.isEmpty, "fixture is empty")
        for row in rows {
            let fontSize = try value(row, 0)
            let expected = try value(row, 1)
            XCTAssertEqual(
                scale.lineHeight(forFontSize: fontSize),
                expected,
                accuracy: tolerance,
                "lineHeight(forFontSize: \(fontSize))"
            )
        }
    }

    func testResolvedMatchesTheFixture() throws {
        for row in try fixture("root-size.tsv") {
            let width = try value(row, 0)
            XCTAssertEqual(scale.resolved(at: width).rootSize, try value(row, 1))
        }
    }

    // MARK: - Fixture loading

    /// Parses a fixture into rows of columns, dropping comments and the header.
    private func fixture(_ name: String) throws -> [[String]] {
        let url = try Self.specDirectory.appendingPathComponent(name)
        let text = try String(contentsOf: url, encoding: .utf8)
        return text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .filter { !$0.hasPrefix("#") }
            .dropFirst()
            .map { $0.split(separator: "\t").map(String.init) }
    }

    private func value(_ row: [String], _ column: Int) throws -> CGFloat {
        guard column < row.count, let parsed = Double(row[column]) else {
            throw FixtureError.unparseable(row: row, column: column)
        }
        return CGFloat(parsed)
    }

    /// Walks up from this source file to find the repository's `spec/`.
    ///
    /// `#filePath` rather than `Bundle.module`, so the fixtures stay a plain
    /// committed directory shared with the other three ports instead of a
    /// resource that has to be copied into this target.
    private static var specDirectory: URL {
        get throws {
            var directory = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
            for _ in 0..<6 {
                let candidate = directory.appendingPathComponent("spec")
                let fixture = candidate.appendingPathComponent("root-size.tsv")
                if FileManager.default.fileExists(atPath: fixture.path) {
                    return candidate
                }
                let parent = directory.deletingLastPathComponent()
                if parent.path == directory.path { break }
                directory = parent
            }
            throw FixtureError.specDirectoryNotFound
        }
    }

    private enum FixtureError: Error, CustomStringConvertible {
        case specDirectoryNotFound
        case unparseable(row: [String], column: Int)

        var description: String {
            switch self {
            case .specDirectoryNotFound:
                return """
                    Could not find spec/root-size.tsv above \(#filePath). \
                    Generate the fixtures with `node spec/generate.mjs`.
                    """
            case let .unparseable(row, column):
                return "Could not read column \(column) of \(row)"
            }
        }
    }
}
