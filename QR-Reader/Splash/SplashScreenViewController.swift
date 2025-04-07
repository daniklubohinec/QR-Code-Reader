//
//  SplashScreenViewController.swift
//  QR-Reader
//
//  Created by Danik Lubohinec on 26.07.24.
//

import UIKit
import Combine

final class SplashScreenViewController: UIViewController {
    
    @IBOutlet private var indicator: UIActivityIndicatorView!
    private var cancelable = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        indicator.startAnimating()
        
        PurchaseService.shared.$inAppPaywall
            .sink { [weak self] paywall in
                guard paywall != nil, let self else {
                    return
                }
                onMain {
                    self.showMainViewController()
                    if !Storage.shared.onboardingShown, !PurchaseService.shared.hasPremium {
                        self.showOnboarding()
                    } else {
                        self.unhideMain()
                    }

                }
            }
            .store(in: &cancelable)
    }
    
    private func showMainViewController() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainViewController = mainStoryboard.instantiateInitialViewController() {
            mainViewController.modalTransitionStyle = .crossDissolve
            mainViewController.modalPresentationStyle = .fullScreen
            
            self.addChild(mainViewController)
            self.view.addSubview(mainViewController.view)
            mainViewController.view.frame = self.view.bounds
            mainViewController.didMove(toParent: self)
            
            mainViewController.view.isHidden = true
        }
    }
    
    private func unhideMain() {
        if let mainViewController = children.first {
            mainViewController.view.isHidden = false
        }
    }
    
    private func showOnboarding() {
        let vc = OnboardingViewController()
        vc.completion = { [weak self] in
            self?.unhideMain()
        }
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false)
    }
}
