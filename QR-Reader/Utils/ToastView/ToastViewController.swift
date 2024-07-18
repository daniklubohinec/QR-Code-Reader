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
        icon.image = UIImage(systemName: imagename!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.dismiss(animated: true)
        }
    }
    
    static func showToast(
        with message: String,
        with imagename: String,
        onViewController: UIViewController? = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
    ) {
        guard let toast = R.storyboard.toast.toastVC.callAsFunction() else { return }
        toast.text = message
        toast.imagename = imagename
        toast.modalPresentationStyle = .overCurrentContext

        onViewController?.present(toast, animated: true)
    }
}
