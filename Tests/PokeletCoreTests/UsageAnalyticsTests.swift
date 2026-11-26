import Foundation
@testable import PokeletCore
import XCTest

@MainActor
final class UsageAnalyticsTests: XCTestCase {
    private let day = Date(timeIntervalSince1970: 4_102_444_800)
    private let appID = "A67A90E5-B72B-430E-834A-3764D2DB00E0"

    func testConsentRestartUpdateAndDailyLimit() async throws {
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let firstStarted = expectation(description: "first request")
        let nextStarted = expectation(description: "next day request")
        let extraRequest = expectation(description: "unexpected request")
        extraRequest.isInverted = true
        let recorder = RequestRecorder([firstStarted, nextStarted], extra: extraRequest)
        RecordingProtocol.recorder = recorder
        defer { RecordingProtocol.recorder = nil }

        let initial = makeAnalytics(defaults, build: "6")
        defer { initial.stop() }
        XCTAssertFalse(initial.isEnabled)
        initial.check(now: day)
        XCTAssertTrue(recorder.requests.isEmpty)

        initial.setEnabled(true, now: day)
        await fulfillment(of: [firstStarted], timeout: 2)
        initial.check(now: day.addingTimeInterval(60))
        initial.stop()

        let restarted = makeAnalytics(defaults, build: "7")
        defer { restarted.stop() }
        XCTAssertTrue(restarted.isEnabled)
        restarted.check(now: day)
        restarted.check(now: day.addingTimeInterval(-86_400))
        restarted.check(now: day.addingTimeInterval(86_400))
        await fulfillment(of: [nextStarted], timeout: 2)
        restarted.check(now: day.addingTimeInterval(90_000))

        await fulfillment(of: [extraRequest], timeout: 0.2)
        let requests = recorder.requests
        guard requests.count == 2 else { return XCTFail("Expected two requests, got \(requests.count)") }
        let first = try decode(requests[0])
        let next = try decode(requests[1])
        XCTAssertEqual(first["type"] as? String, "Usage.firstLaunch")
        XCTAssertEqual(next["type"] as? String, "Usage.active")
        XCTAssertEqual(first["clientUser"] as? String, next["clientUser"] as? String)
        XCTAssertEqual(first["payload"] as? [String: String], ["Pokelet.App.version": "1.3.1 (build 6)"])
        XCTAssertEqual(next["payload"] as? [String: String], ["Pokelet.App.version": "1.3.1 (build 7)"])
    }

    func testWithdrawalCancelsInFlightAndSuppressesFurtherReports() async throws {
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let firstStarted = expectation(description: "first request")
        let cancelled = expectation(description: "in-flight request cancelled")
        let rejoined = expectation(description: "request after renewed consent")
        let extraRequest = expectation(description: "unexpected request")
        extraRequest.isInverted = true
        let recorder = RequestRecorder([firstStarted, rejoined], extra: extraRequest, cancellation: cancelled)
        RecordingProtocol.recorder = recorder
        defer { RecordingProtocol.recorder = nil }

        let analytics = makeAnalytics(defaults)
        defer { analytics.stop() }
        analytics.setEnabled(true, now: day)
        await fulfillment(of: [firstStarted], timeout: 2)
        analytics.setEnabled(false)
        await fulfillment(of: [cancelled], timeout: 2)

        let restarted = makeAnalytics(defaults)
        defer { restarted.stop() }
        XCTAssertFalse(restarted.isEnabled)
        restarted.check(now: day.addingTimeInterval(86_400))
        restarted.setEnabled(true, now: day)
        restarted.check(now: day.addingTimeInterval(86_400))
        await fulfillment(of: [rejoined], timeout: 2)
        await fulfillment(of: [extraRequest], timeout: 0.2)
        let requests = recorder.requests
        guard requests.count == 2 else { return XCTFail("Expected two requests, got \(requests.count)") }
        let original = try decode(requests[0])
        let renewed = try decode(requests[1])
        XCTAssertEqual(renewed["type"] as? String, "Usage.active")
        XCTAssertNotEqual(original["clientUser"] as? String, renewed["clientUser"] as? String)
    }

    func testOfflineRequestIsNeverRetriedAndDeveloperExclusionPersists() async throws {
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let firstStarted = expectation(description: "offline attempt")
        let extraRequest = expectation(description: "unexpected request")
        extraRequest.isInverted = true
        let recorder = RequestRecorder([firstStarted], extra: extraRequest, offline: true)
        RecordingProtocol.recorder = recorder
        defer { RecordingProtocol.recorder = nil }

        let analytics = makeAnalytics(defaults)
        defer { analytics.stop() }
        analytics.setEnabled(true, now: day)
        await fulfillment(of: [firstStarted], timeout: 2)
        analytics.check(now: day.addingTimeInterval(60))
        analytics.stop()

        defaults.set(true, forKey: UsageAnalytics.developerExclusionKey)
        let excluded = makeAnalytics(defaults)
        XCTAssertFalse(excluded.isAvailable)
        XCTAssertFalse(excluded.isEnabled)
        excluded.setEnabled(true, now: day.addingTimeInterval(86_400))
        excluded.check(now: day.addingTimeInterval(86_400))
        let unconfigured = UsageAnalytics(configuration: nil, defaults: defaults) {
            XCTFail("Unavailable build created a transport")
            return .shared
        }
        unconfigured.setEnabled(true, now: day)
        unconfigured.check(now: day)
        XCTAssertFalse(unconfigured.isAvailable)
        await fulfillment(of: [extraRequest], timeout: 0.2)
    }

    func testNamespaceStaysWithinOneIngestPathSegment() {
        let withoutNamespace = UsageAnalytics.Configuration(appID: appID, namespace: nil, version: "1.3.1", build: "6")
        XCTAssertEqual(withoutNamespace?.endpoint.absoluteString, "https://nom.telemetrydeck.com/v2/")
        for namespace in [".", "..", "com..example", "com.example.", "example/other", "example%2Fother", "example\n"] {
            XCTAssertNil(UsageAnalytics.Configuration(appID: appID, namespace: namespace, version: "1.3.1", build: "6"),
                         "Accepted unsafe namespace \(namespace.debugDescription)")
        }
    }

    private func makeAnalytics(_ defaults: UserDefaults, build: String = "6") -> UsageAnalytics {
        let config = UsageAnalytics.Configuration(appID: appID, namespace: "com.example.pokelet", version: "1.3.1", build: build)
        return UsageAnalytics(configuration: config, defaults: defaults) {
            let session = URLSessionConfiguration.ephemeral
            session.protocolClasses = [RecordingProtocol.self]
            return URLSession(configuration: session)
        }
    }

    private func decode(_ request: URLRequest) throws -> [String: Any] {
        XCTAssertEqual(request.url?.absoluteString, "https://nom.telemetrydeck.com/v2/namespace/com.example.pokelet/")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json; charset=utf-8")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "Pokelet")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Language"), "*")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        let body = try readBody(request)
        let batch = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [[String: Any]])
        XCTAssertEqual(batch.count, 1)
        let event = try XCTUnwrap(batch.first)
        XCTAssertEqual(Set(event.keys), ["appID", "clientUser", "type", "payload"])
        XCTAssertEqual(event["appID"] as? String, appID)
        let hash = try XCTUnwrap(event["clientUser"] as? String)
        XCTAssertNotNil(hash.range(of: "^[0-9a-f]{64}$", options: .regularExpression))
        return event
    }

    private func readBody(_ request: URLRequest) throws -> Data {
        if let data = request.httpBody { return data }
        let stream = try XCTUnwrap(request.httpBodyStream)
        stream.open()
        defer { stream.close() }
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)
        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count >= 0 else { throw stream.streamError ?? URLError(.cannotDecodeRawData) }
            if count == 0 { return result }
            result.append(contentsOf: buffer.prefix(count))
        }
    }
}

private final class RecordingProtocol: URLProtocol {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var sharedRecorder: RequestRecorder?
    private var activeRecorder: RequestRecorder?

    static var recorder: RequestRecorder? {
        get { lock.withLock { sharedRecorder } }
        set { lock.withLock { sharedRecorder = newValue } }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let recorder = Self.recorder else { return }
        activeRecorder = recorder
        recorder.record(request)
        if recorder.offline {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
        } else if recorder.cancellation == nil {
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {
        activeRecorder?.recordCancellation()
    }
}

private final class RequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private let expected: [XCTestExpectation]
    private let extra: XCTestExpectation
    private var recorded: [URLRequest] = []
    private var didCancel = false
    let offline: Bool
    let cancellation: XCTestExpectation?

    init(_ expected: [XCTestExpectation], extra: XCTestExpectation,
         cancellation: XCTestExpectation? = nil, offline: Bool = false) {
        self.expected = expected
        self.extra = extra
        self.cancellation = cancellation
        self.offline = offline
    }

    var requests: [URLRequest] { lock.withLock { recorded } }

    func record(_ request: URLRequest) {
        let expectation = lock.withLock {
            let index = recorded.count
            recorded.append(request)
            return index < expected.count ? expected[index] : extra
        }
        expectation.fulfill()
    }

    func recordCancellation() {
        let expectation = lock.withLock {
            guard !didCancel else { return nil as XCTestExpectation? }
            didCancel = true
            return cancellation
        }
        expectation?.fulfill()
    }
}
