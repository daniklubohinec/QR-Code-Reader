import UIKit

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        delegate = self
    }
    
    private func setupViewControllers() {
        let historyVC: HistoryViewController? = {
            let vcs = viewControllers?.compactMap({ $0 as? UINavigationController })
                .reduce(into: [UIViewController](), { $0.append(contentsOf: $1.viewControllers) })
            guard let history = vcs?.first(where: { $0 is HistoryViewController }) as? HistoryViewController else {
                return nil
            }
            return history
        }()
        guard let historyVC else {
            fatalError("HistoryViewController not found in tab bar")
        }
        
        let historyViewModel = HistoryViewModel()
        historyVC.viewModel = historyViewModel
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        HapticGenerator.shared.generateImpact()
    }
}
