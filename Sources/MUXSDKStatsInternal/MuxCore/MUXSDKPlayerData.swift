import MuxCore

extension MUXSDKPlayerData {
    @available(iOS 13, tvOS 13, *)
    func updateWithTiming(_ timing: PlaybackEventTiming) {
        playerPlayheadTime = timing.mediaTime.muxTimeValue
        playerProgramTime = timing.programDate?.muxTimeValue
        playerLiveEdgeProgramTime = timing.liveEdgeProgramDate?.muxTimeValue
    }
}
