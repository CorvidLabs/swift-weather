import XCTest
import Weather
@testable import SVG

final class WeatherIconsTests: XCTestCase {
    // MARK: - Icon Loading Tests

    func testRenderClearDay() {
        let svg = WeatherIcons.render(
            for: .clear,
            isDaytime: true,
            centerX: 200,
            centerY: 200,
            size: 100
        )
        XCTAssertFalse(svg.isEmpty, "Clear day icon should render")
        XCTAssertTrue(svg.contains("rect"), "SVG should contain rect elements")
        XCTAssertTrue(svg.contains("#FFD800"), "Should use sun yellow color")
    }

    func testRenderClearNight() {
        let svg = WeatherIcons.render(
            for: .clear,
            isDaytime: false,
            centerX: 200,
            centerY: 200,
            size: 100
        )
        XCTAssertFalse(svg.isEmpty, "Clear night icon should render")
        XCTAssertTrue(svg.contains("#FFFACD"), "Should use moon white color")
    }

    func testRenderPartlyCloudyDay() {
        let svg = WeatherIcons.render(
            for: .partlyCloudy,
            isDaytime: true,
            centerX: 200,
            centerY: 200,
            size: 100
        )
        XCTAssertFalse(svg.isEmpty, "Partly cloudy day icon should render")
        XCTAssertTrue(svg.contains("#FFD800"), "Should use sun yellow for partly cloudy day")
    }

    func testRenderPartlyCloudyNight() {
        let svg = WeatherIcons.render(
            for: .partlyCloudy,
            isDaytime: false,
            centerX: 200,
            centerY: 200,
            size: 100
        )
        XCTAssertFalse(svg.isEmpty, "Partly cloudy night icon should render")
        XCTAssertTrue(svg.contains("#FFFACD"), "Should use moon white for partly cloudy night")
    }

    func testRenderCloudy() {
        let svgDay = WeatherIcons.render(for: .cloudy, isDaytime: true, centerX: 200, centerY: 200, size: 100)
        let svgNight = WeatherIcons.render(for: .cloudy, isDaytime: false, centerX: 200, centerY: 200, size: 100)

        XCTAssertFalse(svgDay.isEmpty, "Cloudy day icon should render")
        XCTAssertFalse(svgNight.isEmpty, "Cloudy night icon should render")
        XCTAssertTrue(svgDay.contains("#E8E8E8"), "Day cloud should be light (accessible)")
        XCTAssertTrue(svgNight.contains("#B0B0B0"), "Night cloud should be gray")
    }

    func testRenderFog() {
        let svg = WeatherIcons.render(for: .fog, isDaytime: true, centerX: 200, centerY: 200, size: 100)
        XCTAssertFalse(svg.isEmpty, "Fog icon should render")
        XCTAssertTrue(svg.contains("#505050"), "Should use dark fog color for day (accessible)")
    }

    func testRenderRain() {
        let svg = WeatherIcons.render(for: .rain, isDaytime: true, centerX: 200, centerY: 200, size: 100)
        XCTAssertFalse(svg.isEmpty, "Rain icon should render")
        XCTAssertTrue(svg.contains("#40E0FF"), "Should use bright cyan for rain (accessible)")
    }

    func testRenderDrizzle() {
        let svg = WeatherIcons.render(for: .drizzle, isDaytime: true, centerX: 200, centerY: 200, size: 100)
        XCTAssertFalse(svg.isEmpty, "Drizzle icon should render")
        XCTAssertTrue(svg.contains("#40E0FF"), "Should use bright cyan for drizzle (accessible)")
    }

    func testRenderFreezingRain() {
        let svg = WeatherIcons.render(for: .freezingRain, isDaytime: true, centerX: 200, centerY: 200, size: 100)
        XCTAssertFalse(svg.isEmpty, "Freezing rain icon should render")
        XCTAssertTrue(svg.contains("#4080C0"), "Should use dark blue for freezing rain (accessible)")
    }

    func testRenderSnow() {
        let svg = WeatherIcons.render(for: .snow, isDaytime: true, centerX: 200, centerY: 200, size: 100)
        XCTAssertFalse(svg.isEmpty, "Snow icon should render")
        XCTAssertTrue(svg.contains("#4080C0"), "Should use blue for snow on white bg (accessible)")
    }

    func testRenderSleet() {
        let svg = WeatherIcons.render(for: .sleet, isDaytime: true, centerX: 200, centerY: 200, size: 100)
        XCTAssertFalse(svg.isEmpty, "Sleet icon should render")
        XCTAssertTrue(svg.contains("#3060A0"), "Should use dark blue for sleet (accessible)")
    }

    func testRenderThunderstorm() {
        let svg = WeatherIcons.render(for: .thunderstorm, isDaytime: true, centerX: 200, centerY: 200, size: 100)
        XCTAssertFalse(svg.isEmpty, "Thunderstorm icon should render")
        XCTAssertTrue(svg.contains("#FFFF00"), "Should use lightning yellow color")
    }

    func testRenderUnknown() {
        let svg = WeatherIcons.render(for: .unknown, isDaytime: true, centerX: 200, centerY: 200, size: 100)
        XCTAssertFalse(svg.isEmpty, "Unknown icon should render")
        XCTAssertTrue(svg.contains("#E0E0E0"), "Should use light color for unknown (accessible)")
    }

    // MARK: - All Conditions Test

    func testAllConditionsRender() {
        let conditions: [WeatherCondition] = [
            .clear, .partlyCloudy, .cloudy, .fog, .drizzle, .rain,
            .freezingRain, .snow, .sleet, .thunderstorm, .unknown
        ]

        for condition in conditions {
            for isDaytime in [true, false] {
                let svg = WeatherIcons.render(
                    for: condition,
                    isDaytime: isDaytime,
                    centerX: 200,
                    centerY: 200,
                    size: 100
                )
                XCTAssertFalse(svg.isEmpty, "\(condition) \(isDaytime ? "day" : "night") should render")
                XCTAssertTrue(svg.contains("<rect"), "Should contain SVG rect elements")
            }
        }
    }

    // MARK: - Positioning Tests

    func testIconPositioning() {
        let svg = WeatherIcons.render(
            for: .clear,
            isDaytime: true,
            centerX: 100,
            centerY: 100,
            size: 50
        )

        // Icon should be positioned around the center point
        XCTAssertTrue(svg.contains("x=\""), "SVG should have x coordinates")
        XCTAssertTrue(svg.contains("y=\""), "SVG should have y coordinates")
    }

    func testDifferentSizes() {
        let small = WeatherIcons.render(for: .clear, isDaytime: true, centerX: 200, centerY: 200, size: 50)
        let large = WeatherIcons.render(for: .clear, isDaytime: true, centerX: 200, centerY: 200, size: 200)

        // Both should render, larger one should have more content
        XCTAssertFalse(small.isEmpty)
        XCTAssertFalse(large.isEmpty)
    }
}
