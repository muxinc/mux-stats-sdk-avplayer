import MuxCore

extension MUXSDKPlayerData {
    convenience init(copying other: MUXSDKPlayerData) {
        self.init()
        self.update(other.toQuery())
    }

    func updateWithTiming(_ timing: PlaybackEventTiming) {
        playerPlayheadTime = timing.mediaTime.seconds as NSNumber
        playerProgramTime = timing.programDate?.timeIntervalSince1970 as NSNumber?
        playerLiveEdgeProgramTime = timing.liveEdgeProgramDate?.timeIntervalSince1970 as NSNumber?
    }
}
