import AVFoundation

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
