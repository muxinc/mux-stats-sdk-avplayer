//
//  MUXSDKStatsExampleSPMUITests.swift
//  MUXSDKStatsExampleSPMUITests
//

import XCTest
import UniformTypeIdentifiers

final class MUXSDKStatsExampleSPMUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {

    }

    func testBasicAVKitExample() throws {
        let playerLayerExtendedLogFileName = "basic-avkit-example-player-extended-log"

        let application = XCUIApplication()
        application.launchEnvironment = [
            "ENV_KEY": "qr9665qr78dac0hqld9bjofps",
            "PLAYBACK_ID": "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4",
            "PLAYER_EXTENDED_LOG_FILE_NAME": playerLayerExtendedLogFileName
        ]

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "BasicAVKitExample",
            waitFor: "BasicAVKitExampleView",
            application: application
        )

        #if targetEnvironment(simulator)
        try attachPlayerExtendedLog(
            playerLayerExtendedLogFileName: playerLayerExtendedLogFileName
        )
        #endif
    }

    func testPlayerLayerExample() throws {
        let playerLayerExtendedLogFileName = "player-layer-example-player-extended-log"

        let application = XCUIApplication()
        application.launchEnvironment = [
            "ENV_KEY": "qr9665qr78dac0hqld9bjofps",
            "PLAYBACK_ID": "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4",
            "PLAYER_EXTENDED_LOG_FILE_NAME": playerLayerExtendedLogFileName
        ]

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "PlayerLayerExample",
            waitFor: "PlayerLayerExampleView",
            application: application
        )

        #if targetEnvironment(simulator)
        try attachPlayerExtendedLog(
            playerLayerExtendedLogFileName: playerLayerExtendedLogFileName
        )
        #endif
    }

    func testAVQueuePlayerExample() throws {
        let playerLayerExtendedLogFileName = "avqueue-player-example-player-extended-log"

        let application = XCUIApplication()
        application.launchEnvironment = [
            "ENV_KEY": "qr9665qr78dac0hqld9bjofps",
            "PLAYBACK_ID": "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4",
            "PLAYER_EXTENDED_LOG_FILE_NAME": playerLayerExtendedLogFileName
        ]

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "AVQueuePlayerExample",
            waitFor: "AVQueuePlayerExampleView",
            application: application
        )

        #if targetEnvironment(simulator)
        try attachPlayerExtendedLog(
            playerLayerExtendedLogFileName: playerLayerExtendedLogFileName
        )
        #endif
    }

    func testVideoChangeExample() throws {
        let playerLayerExtendedLogFileName = "video-change-example-player-extended-log"

        let application = XCUIApplication()
        application.launchEnvironment = [
            "ENV_KEY": "qr9665qr78dac0hqld9bjofps",
            "PLAYBACK_ID": "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4",
            "PLAYER_EXTENDED_LOG_FILE_NAME": playerLayerExtendedLogFileName
        ]

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "VideoChangeExample",
            waitFor: "VideoChangeExampleView",
            application: application
        )

        #if targetEnvironment(simulator)
        try attachPlayerExtendedLog(
            playerLayerExtendedLogFileName: playerLayerExtendedLogFileName
        )
        #endif
    }

    func testPlayerLayerScalingExample() throws {
        let playerLayerExtendedLogFileName = "player-layer-scaling--example-player-extended-log"

        let application = XCUIApplication()
        application.launchEnvironment = [
            "ENV_KEY": "qr9665qr78dac0hqld9bjofps",
            "PLAYBACK_ID": "qxb01i6T202018GFS02vp9RIe01icTcDCjVzQpmaB00CUisJ4",
            "PLAYER_EXTENDED_LOG_FILE_NAME": playerLayerExtendedLogFileName
        ]

        try launchAndWaitUntilInForeground(
            application: application
        )

        try tapCell(
            cellIdentifier: "PlayerLayerScalingExample",
            waitFor: "PlayerLayerScalingExampleView",
            application: application
        )

        #if targetEnvironment(simulator)
        try attachPlayerExtendedLog(
            playerLayerExtendedLogFileName: playerLayerExtendedLogFileName
        )
        #endif
    }

    func launchAndWaitUntilInForeground(
        application: XCUIApplication
    ) throws {
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

        guard cellElement.exists else {
            XCTFail("Failed to find cell element: \(cellIdentifier)")
            return
        }

        cellElement.tap()

        let viewElement = application.descendants(
            matching: .any
        ).element(
            matching: .any,
            identifier: viewIdentifier
        )

        let isViewElementOnScreen = viewElement.waitForExistence(
            timeout: 150.0
        )

        guard isViewElementOnScreen else {
            XCTFail("Failed to navigate to view element: \(viewIdentifier)")
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

    func attachPlayerExtendedLog(
        playerLayerExtendedLogFileName: String
    ) throws {
        guard let playerExtendedLogDirectoryPath = ProcessInfo().environment["SIMULATOR_SHARED_RESOURCES_DIRECTORY"] else {
            XCTFail("Cannot construct shared resource url")
            return
        }

        let playerExtendedLogDirectoryURL = URL(
            fileURLWithPath: playerExtendedLogDirectoryPath
        )

        let playerExtendedLogFilePath = playerExtendedLogDirectoryURL
        .appendingPathComponent(
            "\(playerLayerExtendedLogFileName).txt",
            conformingTo: .text
        )

        print(playerExtendedLogFilePath)

        guard try playerExtendedLogFilePath.checkResourceIsReachable() else {
            XCTFail("Cannot reach player extended log file at \(playerExtendedLogFilePath).")
            return
        }

        guard FileManager.default
            .fileExists(
                atPath: playerExtendedLogFilePath.relativePath
            ) else {
            print(playerExtendedLogFilePath)
            XCTFail("Missing player extended log file at \(playerExtendedLogFilePath).")
            return
        }

        guard FileManager.default
            .isReadableFile(
                atPath: playerExtendedLogFilePath.relativePath
            ) else {
            XCTFail("Failed to read player extended log file.")
            return
        }

        let data = FileManager.default.contents(
            atPath: playerExtendedLogFilePath.relativePath
        )

        guard let data else {
            XCTFail("Failed to read player extended log file.")
            return
        }

        let string = String(data: data, encoding: .utf8)!

        let attachment = XCTAttachment(
            string: string
        )
        attachment.lifetime = .keepAlways
        add(attachment)

        try FileManager.default.removeItem(
            at: playerExtendedLogFilePath
        )
    }
}
