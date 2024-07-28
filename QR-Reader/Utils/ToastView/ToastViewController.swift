import Foundation
import UIKit

final class ToastViewController: UIViewController {
    @IBOutlet private var label: UILabel!
    @IBOutlet private var icon: UIImageView!
    @IBOutlet private var toastView: UIView!
    
    var text: String?
    var imagename: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toastView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        toastView.clipsToBounds = true
        toastView.layer.cornerRadius = 15
        label.textColor = .white
        label.font = R.font.interMedium(size: 15)
        label.text = text
        assert(imagename != nil)
        var image: UIImage?
        if let symbol = UIImage(systemName: imagename!) {
            image = symbol
        } else {
            image = UIImage(named: imagename!)
        }
        icon.image = image
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.dismiss(animated: true)
        }
    }
    
    static func showToast(
        with message: String,
        with imagename: String,
        onViewController: UIViewController? = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
    ) {
        let presentOn: UIViewController?
        if onViewController is SplashScreenViewController {
            presentOn = onViewController?.presentedViewController
        } else {
            presentOn = onViewController
        }
        guard let toast = R.storyboard.toast.toastVC.callAsFunction() else { return }
        toast.text = message
        toast.imagename = imagename
        toast.modalPresentationStyle = .overCurrentContext
        toast.modalTransitionStyle = .crossDissolve

        HapticGenerator.shared.generateImpact()
        presentOn?.presentWithFade(toast)
    }
}
