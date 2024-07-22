//
//  ActionSheetViewController.swift
//  QR-Reader
//
//  Created by Danik Lubohinec on 13.07.24.
//

import UIKit
import RxSwift

class ActionSheetViewController: UIViewController {
    
    @IBOutlet weak var background: UIView!
    
    @IBOutlet weak var interfaceBackView: UIView!
    
    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    // public
    public var firstAction: (() -> Void) = ({})
    
    // private
    private let disposeBag = DisposeBag()
    
    private var firstActionPrivate: () -> Void = {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        background.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        
        // set actions
        firstActionPrivate = firstAction
        
        // handle first action
        firstButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let strongSelf = self else { return }
                HapticGenerator.shared.generateImpact()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    strongSelf.hide(action: strongSelf.firstActionPrivate)
                }
            })
            .disposed(by: disposeBag)
        
        // handle cancel action
        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let strongSelf = self else { return }
                HapticGenerator.shared.generateImpact()
                strongSelf.hide(action: nil)
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.25) {
            self.background.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    @IBAction
    private func settingsTapped() {
        firstAction()
    }
    
    @IBAction
    private func closeCross(_ sender: Any) {
        hide(action: nil)
    }
    
    @IBAction
    private func close(_ sender: Any) {
        hide(action: nil)
    }
    
    static func showActionSheet(
        firstAction: @escaping (() -> Void),
        onViewController: UIViewController? = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController) {
            
            guard let dialog = R.storyboard.actionSheet.actionSheetViewController() else { return }
            
            dialog.modalPresentationStyle = .overFullScreen
            dialog.firstAction = firstAction
            
            if let delegate = UIApplication.shared.delegate as? AppDelegate,
               let _ = delegate.window?.topViewController() as? ActionSheetViewController { } else {
                   onViewController?.topViewController().present(dialog, animated: true)
               }
        }
    
    private func hide(_ success: Bool = false, action: (() -> Void)?) {
        modalTransitionStyle = .crossDissolve
        self.dismiss(animated: true, completion: {
            guard let action = action else { return }
            action()
        })
    }
    
    private func action(_ success: Bool = false, action: (() -> Void)?) {
        guard let action = action else { return }
        action()
    }
}
