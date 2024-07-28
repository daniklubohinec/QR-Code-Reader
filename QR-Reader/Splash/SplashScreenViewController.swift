//
//  SplashScreenViewController.swift
//  QR-Reader
//
//  Created by Danik Lubohinec on 26.07.24.
//

import UIKit

class SplashScreenViewController: UIViewController {
    
    @IBOutlet private var indicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        indicator.startAnimating()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showMainViewController()
        }
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
