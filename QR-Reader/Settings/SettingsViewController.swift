//
//  SettingsViewController.swift
//  QR-Reader
//
//  Created by Danik Lubohinec on 13.07.24.
//

import UIKit
import RxSwift
import MessageUI

class SettingsViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
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
    
    //MARK: MFMail Compose ViewController Delegate method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    func animateButtonViews() {
        animateButtonView(rateUsButton, rateUsBackView, disposeBag)
        animateButtonView(shareAppButton, shareAppBackView, disposeBag)
        animateButtonView(contactUsButton, contactUsBackView, disposeBag)
        
        animateButtonView(restoreButton, restoreBackView, disposeBag)
        animateButtonView(privacyButton, privacyBackView, disposeBag)
        animateButtonView(termsButton, termsBackView, disposeBag)
    }
    
    @IBAction
    func rateUs() {
        AppReview().requestImmediately()
    }
    
    @IBAction
    func shareApp() {
        let linkToShare = ["https://itunes.apple.com/app/id6575368844"]
        let activityController = UIActivityViewController(activityItems: linkToShare, applicationActivities: nil)
        self.present(activityController, animated: true, completion: nil)
    }
    
    @IBAction
    func contactUs() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["gytdGraBlais45@hotmail.com"])
            present(mail, animated: true)
        } else {
            let alert = UIAlertController(title: "Error", message: "Device is not able to send an email", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Close", style: .cancel)
            alert.addAction(cancel)
            present(alert, animated: true)
        }
    }
    
    
    /// On Onboarding same things
    @IBAction
    private func restoreTapped() {
        Task {
           await PurchaseService.shared.restorePurchases()
        }
    }
    
    @IBAction
    private func privacyTapped() {
        loadURLString("https://docs.google.com/document/d/1fMjSzysmWVI2q7reiGkCYcdrf2BlfvYj5isq0_T7X4E/edit?usp=sharing")
    }
    
    @IBAction
    private func termsOfUseTapped() {
        loadURLString("https://docs.google.com/document/d/1YOAWrkDnrbQ8CL7emMMg51z8RHlG8ix-8-sDWYNiDug/edit?usp=sharing")
    }
}
