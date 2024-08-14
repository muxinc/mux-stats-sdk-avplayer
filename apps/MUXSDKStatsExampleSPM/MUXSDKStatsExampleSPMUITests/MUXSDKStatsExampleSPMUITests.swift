//
//  MUXSDKStatsExampleSPMUITests.swift
//  MUXSDKStatsExampleSPMUITests
//

import XCTest

final class MUXSDKStatsExampleSPMUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBasicAVKitExample() throws {
        let application = XCUIApplication()

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "BasicAVKitExample",
            waitFor: "BasicAVKitExampleView",
            application: application
        )
    }

    func testPlayerLayerExample() throws {
        let application = XCUIApplication()

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "PlayerLayerExample",
            waitFor: "PlayerLayerExampleView",
            application: application
        )
    }

    func testAVQueuePlayerExample() throws {
        let application = XCUIApplication()

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "AVQueuePlayerExample",
            waitFor: "AVQueuePlayerExampleView",
            application: application
        )
    }

    func testVideoChangeExample() throws {
        let application = XCUIApplication()

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "VideoChangeExample",
            waitFor: "VideoChangeExampleView",
            application: application
        )
    }

    func testPlayerLayerScalingExample() throws {
        let application = XCUIApplication()

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "PlayerLayerScalingExample",
            waitFor: "PlayerLayerScalingExampleView",
            application: application
        )
    }

    func launchAndWaitUntilInForeground(
        application: XCUIApplication
    ) throws {
        application.launchEnvironment = [
            "ENV_KEY": "qr9665qr78dac0hqld9bjofps",
            "PLAYBACK_ID": "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4"
        ]
        application.launch()

        let isRunningInForeground = application.wait(
            for: .runningForeground,
            timeout: 5.0
        )

        guard isRunningInForeground else {
            XCTFail("Failed to launch application")
            return
        }
    }

    func tapCell(
        cellIdentifier: String,
        waitFor viewIdentifier: String,
        application: XCUIApplication
    ) throws {
        let cellElement = application.cells.element(
            matching: .cell,
            identifier: cellIdentifier
        )

        cellElement.tap()

        let viewElement = application.descendants(
            matching: .any
        ).element(
            matching: .any,
            identifier: viewIdentifier
        )

        let isViewElementOnScreen = viewElement.waitForExistence(
            timeout: 80.0
        )

        guard isViewElementOnScreen else {

            let elements = application.descendants(matching: .any).allElementsBoundByIndex

            var identifiers = ""

            for element in elements {
                identifiers += "\(element.identifier) | "
            }

            XCTFail("Failed to navigate to view element: \(viewIdentifier) \n elements: \(elements)")
            return
        }

        let isUnknown = application.wait(
            for: .unknown,
            timeout: 25.0
        )

        guard !isUnknown else {
            XCTFail("Application interrupted while playing video")
            return
        }
    }
}
