//
//  MUXSDKStatsCoreDelegate.swift
//  IntegrationTests
//
//  Created by Santiago Puppo on 8/7/25.
//

public func getLastTimestamp(for playerName: String) -> NSNumber? {
    return MUXSDKCore.getPlayheadTimeStamps(forPlayer: playerName).last
}

public func getTimeDeltas(for playerName: String) -> [NSNumber] {
    return MUXSDKCore.getPlayheadTimeDeltas(forPlayer: playerName)
}

public func getEventsAndReset(for playerName: String) -> [MUXSDKBaseEvent]? {
    defer {
        MUXSDKCore.resetCapturedEvents(forPlayer: playerName)
    }
    return MUXSDKCore.getEventsForPlayer(playerName)
}

public func getEvents(for playerName: String) -> [MUXSDKBaseEvent] {
    return MUXSDKCore.getEventsForPlayer(playerName)
}
