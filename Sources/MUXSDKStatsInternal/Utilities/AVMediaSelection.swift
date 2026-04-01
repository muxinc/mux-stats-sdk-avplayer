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

extension AVMetadataIdentifier {

    static let hlsNameAttribute = AVMetadataIdentifier("m3u8/NAME")
}

@available(iOS 15, tvOS 15, *)
extension AVMediaSelectionOption {

    @MainActor
    func loadHLSNameAttributeValue() async -> String? {
        await loadFirstStringValue(for: .hlsNameAttribute)
    }

    @MainActor
    func loadTitle() async -> String? {
        await loadFirstStringValue(for: .commonIdentifierTitle)
    }

    @MainActor
    func loadFirstStringValue(for identifier: AVMetadataIdentifier) async -> String? {
        let metadataItems = AVMetadataItem.metadataItems(
            from: commonMetadata,
            filteredByIdentifier: identifier)

        for item in metadataItems {
            do {
                if let stringValue = try await item.load(.stringValue) {
                    return stringValue
                }
            } catch {
                logger.debug("Failed to load metadata item \(item): \(error)")
            }
        }

        return nil
    }
}
