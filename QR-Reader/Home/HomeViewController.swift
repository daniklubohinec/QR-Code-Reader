//
//  HomeViewController.swift
//  QR-Reader
//
//  Created by Danik Lubohinec on 9.07.24.
//

import UIKit
import RxSwift

class HomeViewController: UIViewController {
    
    @IBOutlet weak var scanBackView: UIView!
    @IBOutlet weak var scanButton: UIButton!
    
    
    @IBOutlet weak var wifiBackView: UIView!
    @IBOutlet weak var wifiButton: UIButton!
    
    @IBOutlet weak var textBackView: UIView!
    @IBOutlet weak var textButton: UIButton!
    
    @IBOutlet weak var urlBackView: UIView!
    @IBOutlet weak var urlButton: UIButton!
    
    @IBOutlet weak var contactBackView: UIView!
    @IBOutlet weak var contactButton: UIButton!
    
    private var onboardingShown: Bool {
        UserDefaults.standard.bool(forKey: "onboardingShown")
    }
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        animateButtonViews()
        navigationItem.backButtonDisplayMode = .minimal
        
        scanButton.rx.tap
            .asDriver()
            .drive(onNext: { _ in
                AuthorizationStatus.checkCameraAndPhotoLibraryAuthorizationStatus { [weak self] status in
                    switch status {
                    case .granted:
                        guard let self, let scannerVC = R.storyboard.qrCodeScanner.qrCodeScanner.callAsFunction() else { return }
                        scannerVC.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(scannerVC, animated: true)
                    case .denied:
                        ActionSheetViewController.showActionSheet {
                            print("Go to settings")
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    func animateButtonViews() {
        animateButtonView(scanButton, scanBackView, disposeBag)
        
        animateButtonView(wifiButton, wifiBackView, disposeBag)
        animateButtonView(textButton, textBackView, disposeBag)
        
        animateButtonView(urlButton, urlBackView, disposeBag)
        animateButtonView(contactButton, contactBackView, disposeBag)
    }
    
    @IBAction
    private func createWifi() {
        openCreate(for: .wifi(.empty))
    }
    
    @IBAction
    func createContact() {
        openCreate(for: .contact(.empty))
    }
    
    @IBAction
    func createText() {
        openCreate(for: .text(.empty))
    }
    
    @IBAction
    func createLink() {
        openCreate(for: .url(.empty))
    }
    
    
    
    private func openCreate(for type: QRCodeType) {
        let vc = QRCodeCreatorViewController(type: type, item: nil)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
