import UIKit

enum OnboardingPage: Int, CaseIterable {
    case reader
    case compatibility
    case create
    case buy
    
    var image: UIImage? {
        switch self {
        case .reader:
            return UIImage(named: "firstScreenImage")
        case .compatibility:
            return UIImage(named: "secondScreenImage")
        case .create:
            return UIImage(named: "thirdScreenImage")
        case .buy:
            return UIImage(named: "fourthScreenImage")
        }
    }
    
    var title: String {
        switch self {
        case .reader:
            return "Qr Code & Barcode Scanner"
        case .compatibility:
            return "Broad Barcode Support"
        case .create:
            return "Create & Customize your own QR Codes"
        case .buy:
            return "Scan & Create QR Codes"
        }
    }
    var subtitle: String {
        switch self {
        case .reader:
            return "Use your phone's camera to scan QR codes quickly with a single tap."
        case .compatibility:
            return "Supports a variety of barcode types, including Data Matrix, EAN, Code39, EAN, and more."
        case .create:
            return "Seamlessly design and share your unique QR codes with friends."
        case .buy:
            return "Scan and create QR codes as much as you want with a 3-day free trial, then $6.99 per week."
        }
    }
    var showPriceOptions: Bool {
        switch self {
        case .reader, .compatibility, .create:
            return false
        case .buy:
            return true
        }
    }
}

final class OnboardingContentPage: UIViewController {
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var continueButton: UIButton!
    private var page: OnboardingPage?
    private var nextTappedImpl: ((OnboardingPage) -> Void)?
    
    func setupView(page: OnboardingPage, nextTapped: @escaping ((OnboardingPage) -> Void)) {
        imageView.image = page.image
        titleLabel.text = page.title
        descriptionLabel.text = page.subtitle
        self.page = page
        self.nextTappedImpl = nextTapped
    }
    
    @IBAction
    private func nextTapped() {
        guard let page else { return }
        nextTappedImpl?(page)
    }
}
