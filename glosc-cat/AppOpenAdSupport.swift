import Combine
import Foundation
import GoogleMobileAds
import SwiftUI
import UIKit
import UserMessagingPlatform

private enum AdMobConfiguration {
    static let productionAppOpenAdUnitID = "ca-app-pub-5978423097771370/6976296485"
    static let testAppOpenAdUnitID = "ca-app-pub-3940256099942544/5575463023"
    static let coldStartMaximumDelayNanoseconds: UInt64 = 1_200_000_000
    static let adExpirationInterval: TimeInterval = 4 * 3_600
}

private enum AppAdRuntime {
    static var isEnabled: Bool {
        let processInfo = ProcessInfo.processInfo
        return processInfo.environment["XCTestConfigurationFilePath"] == nil
            && !processInfo.arguments.contains("DisableAppOpenAds")
            && processInfo.environment["DISABLE_APP_OPEN_ADS"].map { $0 != "1" } != false
    }

    static var appOpenAdUnitID: String {
        #if DEBUG
        return AdMobConfiguration.testAppOpenAdUnitID
        #else
        return AdMobConfiguration.productionAppOpenAdUnitID
        #endif
    }
}

@MainActor
final class AppOpenAdManager: NSObject, ObservableObject {
    @Published private(set) var shouldShowLaunchOverlay = AppAdRuntime.isEnabled
    @Published private(set) var isPrivacyOptionsRequired = false
    @Published private(set) var consentErrorMessage: String?

    private var appOpenAd: AppOpenAd?
    private var isLoadingAd = false
    private var isShowingAd = false
    private var loadTime: Date?
    private var didStart = false
    private var isSceneActive = false
    private var coldStartWindowOpen = false
    private var launchSequenceCompleted = false
    private var launchFallbackTask: Task<Void, Never>?
    private var hasStartedMobileAds = false

    deinit {
        launchFallbackTask?.cancel()
    }

    func startIfNeeded() {
        guard !didStart else { return }
        didStart = true

        guard AppAdRuntime.isEnabled else {
            finishLaunchSequence()
            return
        }

        coldStartWindowOpen = true
        shouldShowLaunchOverlay = true
        scheduleColdStartFallback()

        Task {
            await prepareAdsOnLaunch()
        }
    }

    func handleScenePhase(_ scenePhase: ScenePhase) {
        guard AppAdRuntime.isEnabled else {
            finishLaunchSequence()
            return
        }

        switch scenePhase {
        case .active:
            isSceneActive = true

            if launchSequenceCompleted {
                showWarmStartAdIfAvailable()
            } else {
                attemptColdStartPresentationIfNeeded()
            }
        case .background:
            isSceneActive = false
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func loadAd() async {
        guard AppAdRuntime.isEnabled, ConsentInformation.shared.canRequestAds, !isLoadingAd, !isAdAvailable else { return }
        isLoadingAd = true

        defer {
            isLoadingAd = false
        }

        do {
            let loadedAd = try await AppOpenAd.load(
                with: AppAdRuntime.appOpenAdUnitID,
                request: Request()
            )
            loadedAd.fullScreenContentDelegate = self
            appOpenAd = loadedAd
            loadTime = Date()
            attemptColdStartPresentationIfNeeded()
        } catch {
            appOpenAd = nil
            loadTime = nil
        }
    }

    func presentPrivacyOptionsForm() async {
        guard isPrivacyOptionsRequired else { return }

        do {
            let viewController = try await waitForPresentingViewController()
            try await ConsentForm.presentPrivacyOptionsForm(from: viewController)
            isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
            consentErrorMessage = nil
        } catch {
            consentErrorMessage = L10n.tr("privacy.options.error")
        }
    }

    private var isAdAvailable: Bool {
        guard let loadTime else { return false }
        return appOpenAd != nil && Date().timeIntervalSince(loadTime) < AdMobConfiguration.adExpirationInterval
    }

    private func prepareAdsOnLaunch() async {
        let canRequestAds = await refreshConsentState()

        guard AppAdRuntime.isEnabled else {
            finishLaunchSequence()
            return
        }

        guard canRequestAds else {
            finishLaunchSequence()
            return
        }

        startMobileAdsIfNeeded()
        await loadAd()
        attemptColdStartPresentationIfNeeded()
    }

    private func refreshConsentState() async -> Bool {
        do {
            try await requestConsentInfoUpdate()
            isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required

            let viewController = try await waitForPresentingViewController()
            try await ConsentForm.loadAndPresentIfRequired(from: viewController)

            isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
            consentErrorMessage = nil
        } catch {
            consentErrorMessage = L10n.tr("privacy.consent.error")
        }

        return ConsentInformation.shared.canRequestAds
    }

    private func requestConsentInfoUpdate() async throws {
        let parameters = RequestParameters()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func waitForPresentingViewController() async throws -> UIViewController {
        for _ in 0..<20 {
            if let viewController = activeViewController() {
                return viewController
            }

            try await Task.sleep(nanoseconds: 100_000_000)
        }

        throw ConsentFlowError.missingPresentationContext
    }

    private func activeViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .topMostPresentedViewController
    }

    private func startMobileAdsIfNeeded() {
        guard !hasStartedMobileAds else { return }
        hasStartedMobileAds = true
        MobileAds.shared.start()
    }

    private func scheduleColdStartFallback() {
        launchFallbackTask?.cancel()
        launchFallbackTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: AdMobConfiguration.coldStartMaximumDelayNanoseconds)
            guard !Task.isCancelled else { return }
            self?.finishLaunchSequence()
        }
    }

    private func attemptColdStartPresentationIfNeeded() {
        guard coldStartWindowOpen, isSceneActive, !launchSequenceCompleted else { return }
        presentAdIfAvailable()
    }

    private func showWarmStartAdIfAvailable() {
        guard ConsentInformation.shared.canRequestAds else { return }
        presentAdIfAvailable()
    }

    private func presentAdIfAvailable() {
        guard !isShowingAd else { return }

        guard let appOpenAd, isAdAvailable else {
            Task {
                await loadAd()
            }
            return
        }

        isShowingAd = true
        appOpenAd.present(from: nil)
    }

    private func finishLaunchSequence() {
        coldStartWindowOpen = false
        launchSequenceCompleted = true
        shouldShowLaunchOverlay = false
        launchFallbackTask?.cancel()
        launchFallbackTask = nil
    }

    private func clearCurrentAd() {
        appOpenAd = nil
        loadTime = nil
        isShowingAd = false
    }
}

private enum ConsentFlowError: LocalizedError {
    case missingPresentationContext
}

private extension UIViewController {
    var topMostPresentedViewController: UIViewController {
        var candidate = self

        while let presentedViewController = candidate.presentedViewController {
            candidate = presentedViewController
        }

        if let navigationController = candidate as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.topMostPresentedViewController
        }

        if let tabBarController = candidate as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.topMostPresentedViewController
        }

        return candidate
    }
}

extension AppOpenAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        clearCurrentAd()
        finishLaunchSequence()

        Task {
            await loadAd()
        }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        clearCurrentAd()
        finishLaunchSequence()

        Task {
            await loadAd()
        }
    }
}

struct AppLaunchOverlayView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.cream, AppPalette.background, AppPalette.peach.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(AppPalette.white.opacity(0.88))
                        .frame(width: 118, height: 118)
                        .shadow(color: AppPalette.shadow, radius: 22, x: 0, y: 14)

                    Circle()
                        .fill(AppPalette.peach.opacity(0.3))
                        .frame(width: 146, height: 146)

                    Image(systemName: "cat.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(AppPalette.coral)
                }

                VStack(spacing: 10) {
                    Text(L10n.tr("launch.overlay.title"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.ink)

                    Text(L10n.tr("launch.overlay.subtitle"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppPalette.ink.opacity(0.76))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 260)
                }

                ProgressView()
                    .tint(AppPalette.coral)
                    .scaleEffect(1.1)
            }
            .padding(28)
        }
        .accessibilityIdentifier("launch.overlay")
    }
}