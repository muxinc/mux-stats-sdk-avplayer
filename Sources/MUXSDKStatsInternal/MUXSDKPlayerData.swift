import MuxCore

extension MUXSDKPlayerData {
    convenience init(copying other: MUXSDKPlayerData) {
        self.init()
        self.update(other.toQuery())
    }

    @available(iOS 13, tvOS 13, *)
    func updateWithTiming(_ timing: PlaybackEventTiming) {
        playerPlayheadTime = timing.mediaTime.muxTimeValue
        playerProgramTime = timing.programDate?.muxTimeValue
        playerLiveEdgeProgramTime = timing.liveEdgeProgramDate?.muxTimeValue
    }
}
