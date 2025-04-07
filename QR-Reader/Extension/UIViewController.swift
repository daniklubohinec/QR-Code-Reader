//
//  UIViewController.swift
//  QR-Reader
//
//  Created by Danik Lubohinec on 13.07.24.
//

import Foundation
import RxSwift

extension UIViewController {
    func topViewController() -> UIViewController {
        var topController = self
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
    
    func present(_ viewControllerToPresent: UIViewController?, animated flag: Bool, completion: (() -> Void)? = nil) {
        guard let viewController = viewControllerToPresent else {
            return
        }
        self.present(viewController, animated: flag, completion: completion)
    }
    
    func animateButtonView(_ button: UIButton, _ backView: UIView, _ disposeBag: DisposeBag) {
        button.rx.controlEvent(.touchDown)
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { _ in
                backView.alpha = 0.75
            })
            .disposed(by: disposeBag)
        
        button.rx.controlEvent([.touchUpInside, .touchUpOutside, .touchDragExit, .touchCancel])
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { _ in
                backView.alpha = 1
            })
            .disposed(by: disposeBag)
    }
    
    func loadURLString(_ link: String) {
        guard let url = URL(string: link) else { return }
        UIApplication.shared.open(url)
    }
}
