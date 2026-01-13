import Foundation
import MuxCore
import Network

struct NetworkState: Hashable, Sendable {
    let connectionType: MUXSDKConnectionType
    let isLowDataMode: Bool?
}

extension NetworkState {
    init(path: NWPath) {
        if path.status == .unsatisfied {
            connectionType = .noConnection
        } else if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
        } else {
            connectionType = .other
        }

#if compiler(>=6.2)
        if #available(iOS 26, tvOS 26, visionOS 26, *) {
            isLowDataMode = path.isConstrained || path.isUltraConstrained
            return
        }
#endif

        if #available(iOS 13, tvOS 13, *) {
            isLowDataMode = path.isConstrained
        } else {
            isLowDataMode = nil
        }
    }
}

extension MUXSDKNetworkChangeEvent {
    convenience init(networkState: NetworkState) {
        self.init(
            viewerConnectionType: networkState.connectionType,
            viewerConnectionIsLowDataMode: networkState.isLowDataMode as NSNumber?)
    }
}

@objc(MUXSDKNetworkMonitor)
@MainActor public final class NetworkMonitor: NSObject {

    private let onEvent: @Sendable @MainActor (MUXSDKNetworkChangeEvent) -> Void

    private let pathMonitor = NWPathMonitor()

    private(set) var networkState: NetworkState? {
        didSet {
            if let networkState, networkState != oldValue {
                onEvent(MUXSDKNetworkChangeEvent(networkState: networkState))
            }
        }
    }

    @objc nonisolated public init(eventHandler onEvent: @Sendable @escaping @MainActor (MUXSDKNetworkChangeEvent) -> Void) {
        self.onEvent = onEvent
        super.init()
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard #available(iOS 13, tvOS 13, *) else {
                DispatchQueue.main.async {
                    self?.networkState = NetworkState(path: path)
                }
                return
            }
            MainActor.assumeIsolated {
                self?.networkState = NetworkState(path: path)
            }
        }
        pathMonitor.start(queue: .main)
    }

    private func triggerNetworkChangeEventIsolated() {
        guard let networkState else {
            return
        }
        onEvent(MUXSDKNetworkChangeEvent(networkState: networkState))
    }

    @objc nonisolated public func triggerNetworkChangeEvent() {
        guard #available(iOS 13, tvOS 13, *), DispatchQueue.isMainQueue else {
            DispatchQueue.main.async { [weak self] in
                self?.triggerNetworkChangeEventIsolated()
            }
            return
        }
        MainActor.assumeIsolated {
            triggerNetworkChangeEventIsolated()
        }
    }
}
