import AVFoundation

@available(iOS 15, tvOS 15, *)
extension AVMediaSelection {

    @MainActor
    func selectedMediaOptionInGroup(for mediaCharacteristic: AVMediaCharacteristic) async -> AVMediaSelectionOption? {
        guard let asset else {
            return nil
        }

        let group: AVMediaSelectionGroup?
        do {
            group = try await asset.loadMediaSelectionGroup(for: mediaCharacteristic)
        } catch {
            logger.debug("Failed to load group for \(mediaCharacteristic.rawValue): \(error)")
            return nil
        }

        guard let group, let selected = selectedMediaOption(in: group) else {
            return nil
        }

        return selected
    }
}
