import Combine
import CryptoKit
import Foundation

@MainActor
final class UsageAnalytics: ObservableObject {
    static let developerExclusionKey = "PokeletAnalyticsDeveloperExcluded"

    struct Configuration {
        let appID: UUID
        let endpoint: URL
        let version: String

        init?(appID: String?, namespace: String?, version: String?, build: String?) {
            guard let appID, let identifier = UUID(uuidString: appID),
                  let version, let build, !version.isEmpty, !build.isEmpty else { return nil }
            let namespace = namespace ?? ""
            let namespacePattern = #"\A[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)*\z"#
            guard namespace.isEmpty || namespace.range(of: namespacePattern, options: .regularExpression) != nil else {
                return nil
            }
            let path = namespace.isEmpty ? "/v2/" : "/v2/namespace/\(namespace)/"
            guard let endpoint = URL(string: "https://nom.telemetrydeck.com" + path) else { return nil }
            self.appID = identifier
            self.endpoint = endpoint
            self.version = "\(version) (build \(build))"
        }
    }

    private struct Consent: Codable {
        let revision: Int
        let grantedAt: Date
        let installationID: UUID
    }

    private struct State: Codable {
        var consent: Consent?
        var lastAttemptDay: Int?
    }

    private struct Event: Encodable {
        let appID: UUID
        let clientUser: String
        let type: String
        let payload: [String: String]
    }

    private static let stateKey = "PokeletUsageAnalytics"
    private static let noticeRevision = 2
    private static let secondsPerDay: TimeInterval = 86_400

    @Published private(set) var isEnabled = false
    let isAvailable: Bool

    private let configuration: Configuration?
    private let defaults: UserDefaults
    private let makeSession: () -> URLSession
    private var timer: Timer?
    private var session: URLSession?

    init(configuration: Configuration?, defaults: UserDefaults = .standard,
         makeSession: @escaping () -> URLSession = { UsageAnalytics.makeEphemeralSession() }) {
        self.defaults = defaults
        self.configuration = configuration
        self.makeSession = makeSession
        isAvailable = configuration != nil && !defaults.bool(forKey: Self.developerExclusionKey)
        let stored = state
        if let consent = stored.consent, consent.revision < Self.noticeRevision {
            setEnabled(false)
        } else {
            isEnabled = isAvailable && stored.consent?.revision == Self.noticeRevision
        }
    }

    private var state: State {
        guard let data = defaults.data(forKey: Self.stateKey),
              let state = try? JSONDecoder().decode(State.self, from: data) else { return State() }
        return state
    }

    func setEnabled(_ enabled: Bool, now: Date = .now) {
        var state = state
        if enabled {
            guard !isEnabled, isAvailable, !defaults.bool(forKey: Self.developerExclusionKey) else { return }
            state.consent = Consent(revision: Self.noticeRevision, grantedAt: now, installationID: UUID())
            guard save(state) else { return }
            isEnabled = true
            check(now: now)
        } else {
            isEnabled = false
            stop()
            guard state.consent != nil else { return }
            state.consent = nil
            _ = save(state)
        }
    }

    func check(now: Date = .now) {
        guard isEnabled, let configuration, !defaults.bool(forKey: Self.developerExclusionKey) else {
            stop()
            return
        }
        var state = state
        guard let consent = state.consent, consent.revision == Self.noticeRevision else {
            isEnabled = false
            stop()
            return
        }

        let day = Int(floor(now.timeIntervalSince1970 / Self.secondsPerDay))
        scheduleCheck(after: day)
        if let lastAttemptDay = state.lastAttemptDay, lastAttemptDay >= day { return }

        let hash = SHA256.hash(data: Data((consent.installationID.uuidString + configuration.appID.uuidString).utf8))
        let event = Event(
            appID: configuration.appID,
            clientUser: hash.map { String(format: "%02x", $0) }.joined(),
            type: state.lastAttemptDay == nil ? "Usage.firstLaunch" : "Usage.active",
            payload: ["Pokelet.App.version": configuration.version]
        )
        guard let body = try? JSONEncoder().encode([event]) else { return }

        // Reserve the day before sending. An offline or ambiguous delivery is never replayed.
        state.lastAttemptDay = day
        guard save(state) else { return }
        var request = URLRequest(url: configuration.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Pokelet", forHTTPHeaderField: "User-Agent")
        request.setValue("*", forHTTPHeaderField: "Accept-Language")
        request.httpBody = body

        let session = self.session ?? makeSession()
        self.session = session
        session.dataTask(with: request) { _, _, _ in }.resume()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        session?.invalidateAndCancel()
        session = nil
    }

    private func save(_ state: State) -> Bool {
        guard let data = try? JSONEncoder().encode(state) else { return false }
        defaults.set(data, forKey: Self.stateKey)
        return true
    }

    private func scheduleCheck(after utcDay: Int) {
        let nextDay = Date(timeIntervalSince1970: Double(utcDay + 1) * Self.secondsPerDay)
        guard timer?.fireDate != nextDay else { return }
        timer?.invalidate()
        let timer = Timer(fire: nextDay, interval: 0, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.timer = nil
                self?.check()
            }
        }
        timer.tolerance = 60
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    nonisolated static func makeEphemeralSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        return URLSession(configuration: configuration, delegate: NoRedirects(), delegateQueue: nil)
    }

    private final class NoRedirects: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                        completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
            completionHandler(nil)
        }
    }
}
