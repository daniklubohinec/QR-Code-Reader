//
//  HomeViewController.swift
//  QR-Reader
//
//  Created by Danik Lubohinec on 9.07.24.
//

import UIKit
import RxSwift
import Contacts
import ContactsUI

final class HomeViewController: UIViewController {
    
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
    
    private lazy var contactFlow: ContactSelectFeature = {
        return ContactSelectFeature(
            presenting: self,
            onSelectedContact: { [weak self] in
                self?.openCreateFrom(contact: $0)
            }
        )
    }()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        animateButtonViews()
        navigationItem.backButtonDisplayMode = .minimal
        
        scanButton.rx.tap
            .asDriver()
            .drive(onNext: { _ in
                HapticGenerator.shared.generateImpact()
                AuthorizationStatus.checkCameraAndPhotoLibraryAuthorizationStatus { [weak self] status in
                    switch status {
                    case .granted:
                        guard let self, let scannerVC = R.storyboard.qrCodeScanner.qrCodeScanner.callAsFunction() else { return }
                        scannerVC.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(scannerVC, animated: true)
                    case .denied:
                        ActionSheetViewController.showActionSheet { [weak self] in
                            self?.openAppSettings()
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
        if !Storage.shared.onboardingShown {
            let vc = OnboardingViewController()
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: false)
        }
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
        HapticGenerator.shared.generateImpact()
        openCreate(for: .wifi)
    }
    
    @IBAction
    func createContact() {
        HapticGenerator.shared.generateImpact()
        showContactOptions()
    }
    
    @IBAction
    func createText() {
        HapticGenerator.shared.generateImpact()
        openCreate(for: .text)
    }
    
    @IBAction
    func createLink() {
        HapticGenerator.shared.generateImpact()
        openCreate(for: .url)
    }
    
    private func openCreate(for type: QRCodeData.QRCodeType, data: QRCodeData? = nil) {
        if hasSubscription {
            let vc = QRCodeCreatorViewController(type: type, state: .creating)
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = OnboardingViewController(pages: [.buy])
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }
    
    private func showContactOptions() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let importContact = UIAlertAction(title: "Choose from Contacts", style: .default) { [weak self] _ in
            HapticGenerator.shared.generateImpact()
            self?.contactFlow.showContactPicker()
        }
        let manual = UIAlertAction(title: "Enter Manually", style: .default) { [weak self] _ in
            HapticGenerator.shared.generateImpact()
            self?.openCreate(for: .contact)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        [importContact, manual, cancel].forEach { sheet.addAction($0) }
        present(sheet, animated: true)
    }
    
    private func openCreateFrom(contact: CNContact) {
        openCreate(for: .contact, data: contact.contactQRModel)
    }
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

final class ContactSelectFeature: NSObject, CNContactPickerDelegate {
    private let store = CNContactStore()
    private weak var parent: UIViewController?
    private let onSelectedContact: ((CNContact) -> Void)

    init(
        presenting: UIViewController,
        onSelectedContact: @escaping ((CNContact) -> Void)
    ) {
        self.parent = presenting
        self.onSelectedContact = onSelectedContact
    }
    
    func showContactPicker() {
        store.requestAccess(for: .contacts) { [weak self] granted, error in
            guard granted else {
                return
            }
            onMain {
                self?.openContactPicker()
            }
        }
    }
    
    private func openContactPicker() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        // Вы можете настроить, какие свойства контактов показывать
        contactPicker.displayedPropertyKeys = [CNContactGivenNameKey, CNContactPhoneNumbersKey]

        parent?.present(contactPicker, animated: true, completion: nil)
    }

    // MARK: - CNContactPickerDelegate Methods

    internal func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        onSelectedContact(contact)
    }

    internal func contactPickerDidCancel(_ picker: CNContactPickerViewController) {

    }
}
extension CNContact {
    var contactQRModel: QRCodeData {
        let phone = phoneNumbers.first?.value.stringValue ?? ""
        let mail = emailAddresses.first?.value as String?
        let url = urlAddresses.first?.value as String?
        
        return QRCodeData(
            type: .contact,
            data: [
                "Contact Name": "\(familyName) \(givenName)",
                "Phone Number": phone,
                "Mail": mail ?? "",
                "URL": url ?? ""
            ]
        )
    }
}
