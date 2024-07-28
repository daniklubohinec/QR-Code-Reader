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
                }
            }
            .store(in: &cancelable)
    }
    
    private func showMainViewController() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainViewController = mainStoryboard.instantiateInitialViewController() {
            mainViewController.modalTransitionStyle = .crossDissolve
            mainViewController.modalPresentationStyle = .fullScreen
            self.present(mainViewController, animated: true, completion: nil)
        }
    }
}
