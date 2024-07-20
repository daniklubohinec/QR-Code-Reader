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
            return "Instant QR Code Reader"
        case .compatibility:
            return "Wide Barcode Compatibility"
        case .create:
            return "Create and Share QR Codes"
        case .buy:
            return "QR Code Scanning and Generating"
        }
    }
    var subtitle: String {
        switch self {
        case .reader:
            return "Quickly scan QR codes with a single tap using your phone's camera."
        case .compatibility:
            return "Compatible with various barcode types including Data Matrix, EAN, Code128, UPC, and more."
        case .create:
            return "Easily generate and share your custom QR codes with friends."
        case .buy:
            return "Enjoy unlimited QR code scanning and generating with a 3-day free trial, then $6.99 per week."
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
