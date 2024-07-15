//
//  SettingsViewController.swift
//  QR-Reader
//
//  Created by Danik Lubohinec on 13.07.24.
//

import UIKit
import RxSwift

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var rateUsBackView: UIView!
    @IBOutlet weak var rateUsButton: UIButton!
    
    @IBOutlet weak var shareAppBackView: UIView!
    @IBOutlet weak var shareAppButton: UIButton!
    
    @IBOutlet weak var contactUsBackView: UIView!
    @IBOutlet weak var contactUsButton: UIButton!
    
    @IBOutlet weak var restoreBackView: UIView!
    @IBOutlet weak var restoreButton: UIButton!
    
    @IBOutlet weak var privacyBackView: UIView!
    @IBOutlet weak var privacyButton: UIButton!
    
    @IBOutlet weak var termsBackView: UIView!
    @IBOutlet weak var termsButton: UIButton!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        animateButtonViews()
    }
    
    func animateButtonViews() {
        animateButtonView(rateUsButton, rateUsBackView, disposeBag)
        animateButtonView(shareAppButton, shareAppBackView, disposeBag)
        animateButtonView(contactUsButton, contactUsBackView, disposeBag)
        
        animateButtonView(restoreButton, restoreBackView, disposeBag)
        animateButtonView(privacyButton, privacyBackView, disposeBag)
        animateButtonView(termsButton, termsBackView, disposeBag)
    }
}

