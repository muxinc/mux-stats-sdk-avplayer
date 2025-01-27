//
//  ProcessInfo+Mux.swift
//  MUXSDKStatsExampleSPM
//

import Foundation

extension ProcessInfo {
    var environmentKey: String? {
        guard let value = environment["ENV_KEY"],
                !value.isEmpty else {
            return nil
        }

        return value
    }

    var playbackID: String? {
        guard let value = environment["PLAYBACK_ID"],
                !value.isEmpty else {
            return nil
        }

        return value
    }

    var playerExtendedLogFilePath: String? {
        guard let value = environment["PLAYER_EXTENDED_LOG_FILE_PATH"],
              !value.isEmpty else {
            return nil
        }
        
        return value
    }

    var simulatorSharedResourcesDirectory: String? {
        guard let value = environment["SIMULATOR_SHARED_RESOURCES_DIRECTORY"],
              !value.isEmpty else {
            return nil
        }

        return value
    }

    var playerExtendedLogFileName: String? {
        guard let value = environment["PLAYER_EXTENDED_LOG_FILE_NAME"],
              !value.isEmpty else {
            return nil
        }

        return value
    }
}
