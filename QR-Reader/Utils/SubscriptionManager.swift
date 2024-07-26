import Foundation
import Adapty

final class SubscriptionManager {
    static let shared = SubscriptionManager()
    
    var hasSubscription = false
    var ninjamode = false
    
    init() {
        DispatchQueue.global().async {
            Adapty.delegate = self
            Adapty.getProfile { [weak self] result in
                guard let profile = try? result.get() else {
                    return
                }
                if profile.accessLevels.isEmpty {
                    self?.hasSubscription = false
                } else {
                    self?.hasSubscription = true
                }
            }
            Adapty.getPaywall(placementId: "onboarding_paywall") { [weak self] result in
                guard let paywall = try? result.get() else { return }
                self?.ninjamode = (paywall.remoteConfig?["mode"] as? Bool) ?? false
                Adapty.getPaywallProducts(paywall: paywall) { result in
                    guard let products = try? result.get() else { return }
                    print(products)
                }
            }
        }
    }
}
extension SubscriptionManager: AdaptyDelegate {
    func didLoadLatestProfile(_ profile: AdaptyProfile) {
        if profile.accessLevels.isEmpty {
            hasSubscription = false
        } else {
            hasSubscription = true
        }
    }
}
