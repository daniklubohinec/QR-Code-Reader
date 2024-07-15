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
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        animateButtonViews()
        
        scanButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] _ in
                ActionSheetViewController.showActionSheet {
                    print("Go to settings")
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
}
