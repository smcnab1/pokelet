import Combine
import Foundation
#if DEBUG || POKELET_SIGNED_UPDATES
import OSLog
import Sparkle
#endif

@MainActor
final class UpdateService: NSObject, ObservableObject {
    @Published private(set) var isAvailable = false
    @Published private(set) var canCheck = false
    @Published private(set) var automaticallyChecks = false
    @Published private(set) var sessionInProgress = false
    @Published private(set) var pendingVersion: String?
    @Published private(set) var lastCheck: Date?
    @Published private(set) var result: CheckResult?
    @Published private(set) var offersWhatsNew = false

    enum CheckResult {
        case noUpdate, offline, feedError, verificationFailed, installLocation, otherError

        var message: String {
            switch self {
            case .noUpdate: "No compatible update is available."
            case .offline: "Pokelet couldn’t reach the update service. Check your connection and try again."
            case .feedError: "Pokelet couldn’t read or verify the update feed. Try again later or use GitHub Releases."
            case .verificationFailed: "Sparkle couldn’t verify the update. Retry later or use the verified installer from GitHub Releases."
            case .installLocation: "Move Pokelet to Applications and reopen it before checking for updates."
            case .otherError: "The update couldn’t be completed. Try again or use GitHub Releases to install it manually."
            }
        }
    }

    #if DEBUG
    static let acceptanceBundleID = "uk.co.sammcnab.Pokelet.UpdateAcceptance"
    #endif
    #if DEBUG || POKELET_SIGNED_UPDATES
    private static let log = Logger(subsystem: "uk.co.sammcnab.Pokelet", category: "Updates")
    #endif

    let version: String
    let build: String
    let releases: [ReleaseNote]
    let currentRelease: ReleaseNote?

    private let history: ReleaseHistory?
    private let hasLegacyPreferences: Bool
    #if DEBUG || POKELET_SIGNED_UPDATES
    private let feed: String?
    private var controller: SPUStandardUpdaterController?
    private var observations: Set<AnyCancellable> = []
    #endif

    init(bundle: Bundle = .main, defaults: UserDefaults? = .standard) {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        self.version = version
        self.build = build
        let changelog = bundle.url(forResource: "CHANGELOG", withExtension: "md")
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) }
        releases = ReleaseNote.parse(changelog ?? "")
        currentRelease = releases.first { $0.version == version && String($0.build) == build }
        #if DEBUG || POKELET_SIGNED_UPDATES
        feed = Self.configuredFeed(in: bundle)
        #endif
        history = defaults.map(ReleaseHistory.init(defaults:))
        hasLegacyPreferences = defaults?.data(forKey: PreferenceStore.key) != nil
        super.init()
    }

    func start() {
        offersWhatsNew = history?.shouldOffer(build: Int(build) ?? 0, hasNotes: currentRelease != nil,
                                             hasLegacyPreferences: hasLegacyPreferences) ?? false
        #if DEBUG || POKELET_SIGNED_UPDATES
        guard feed != nil, controller == nil else { return }

        let controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: self, userDriverDelegate: self)
        let updater = controller.updater
        updater.sendsSystemProfile = false
        do {
            try updater.start()
        } catch {
            Self.log.error("Sparkle could not start: \(error.localizedDescription, privacy: .private)")
            return
        }
        self.controller = controller
        isAvailable = true
        lastCheck = updater.lastUpdateCheckDate
        updater.publisher(for: \.canCheckForUpdates)
            .sink { [weak self] in self?.canCheck = $0 }.store(in: &observations)
        updater.publisher(for: \.automaticallyChecksForUpdates)
            .sink { [weak self] in self?.automaticallyChecks = $0 }.store(in: &observations)
        updater.publisher(for: \.sessionInProgress)
            .sink { [weak self] in self?.sessionInProgress = $0 }.store(in: &observations)
        #endif
    }

    func setAutomaticChecks(_ enabled: Bool) {
        #if DEBUG || POKELET_SIGNED_UPDATES
        controller?.updater.automaticallyChecksForUpdates = enabled
        #endif
    }

    func checkForUpdates() {
        #if DEBUG || POKELET_SIGNED_UPDATES
        guard canCheck else { return }
        result = nil
        controller?.checkForUpdates(nil)
        #endif
    }

    func markWhatsNewSeen() {
        guard let currentRelease else { return }
        history?.markSeen(build: currentRelease.build)
        offersWhatsNew = false
    }
}

#if DEBUG || POKELET_SIGNED_UPDATES
// Sparkle's standard user driver invokes these callbacks on the main thread.
extension UpdateService: SPUUpdaterDelegate, @preconcurrency SPUStandardUserDriverDelegate {
    func feedURLString(for updater: SPUUpdater) -> String? { feed }

    // Keep Sparkle's native prompt in reserve until the user chooses to see it.
    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem,
                                                              andInImmediateFocus immediateFocus: Bool) -> Bool {
        false
    }

    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem,
                                                   state: SPUUserUpdateState) {
        if !handleShowingUpdate {
            result = nil
            pendingVersion = update.displayVersionString
            lastCheck = controller?.updater.lastUpdateCheckDate
        }
    }

    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        pendingVersion = nil
    }

    func standardUserDriverWillFinishUpdateSession() {
        pendingVersion = nil
    }

    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
        lastCheck = updater.lastUpdateCheckDate
        result = (error as NSError?).flatMap(Self.checkResult)
    }

    private static func checkResult(_ error: NSError) -> CheckResult? {
        if error.domain == NSURLErrorDomain {
            switch error.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorTimedOut,
                 NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return .offline
            default: break
            }
        }
        if error.domain == SUSparkleErrorDomain {
            switch error.code {
            case Int(SUError.noUpdateError.rawValue): return .noUpdate
            case Int(SUError.appcastParseError.rawValue): return .feedError
            case Int(SUError.signatureError.rawValue), Int(SUError.validationError.rawValue): return .verificationFailed
            case Int(SUError.runningFromDiskImageError.rawValue), Int(SUError.runningTranslocated.rawValue),
                 Int(SUError.installationWriteNoPermissionError.rawValue): return .installLocation
            case Int(SUError.installationCanceledError.rawValue),
                 Int(SUError.installationAuthorizeLaterError.rawValue): return nil
            default: break
            }
        }
        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            return checkResult(underlying)
        }
        return .otherError
    }

    private static func configuredFeed(in bundle: Bundle) -> String? {
        func value(_ key: String) -> Any? { bundle.object(forInfoDictionaryKey: key) }
        guard let rawFeed = value("SUFeedURL") as? String, let url = URLComponents(string: rawFeed),
              let key = value("SUPublicEDKey") as? String, Data(base64Encoded: key)?.count == 32,
              value("SURequireSignedFeed") as? Bool == true,
              value("SUVerifyUpdateBeforeExtraction") as? Bool == true,
              value("SUSignedFeedFailureExpirationInterval") as? Int == 0,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else { return nil }
        #if DEBUG
        if bundle.bundleIdentifier == acceptanceBundleID, url.scheme == "http", url.host == "127.0.0.1",
           url.port != nil, url.path == "/appcast.xml" {
            return rawFeed
        }
        #else
        if bundle.bundleIdentifier == "uk.co.sammcnab.Pokelet",
           rawFeed == "https://smcnab1.github.io/pokelet/updates/appcast.xml" { return rawFeed }
        #endif
        return nil
    }
}
#endif
