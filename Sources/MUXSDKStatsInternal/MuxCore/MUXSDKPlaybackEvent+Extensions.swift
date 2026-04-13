import MuxCore

extension MUXSDKPlaybackEvent {

    var lazyPlayerData: MUXSDKPlayerData {
        if let playerData {
            return playerData
        }
        let created = MUXSDKPlayerData()
        self.playerData = created
        return created
    }

    @available(iOS 13, tvOS 13, *)
    func updateWithTiming(_ timing: PlaybackEventTiming) {
        lazyPlayerData.updateWithTiming(timing)
    }
}
