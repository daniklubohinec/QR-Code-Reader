import UIKit
import AVFoundation

final class QRCodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var galleryButton: UIButton! {
        didSet {
            galleryButton.clipsToBounds = true
            galleryButton.layer.cornerRadius = 15
        }
    }
    @IBOutlet private var flashButton: UIButton! {
        didSet {
            flashButton.clipsToBounds = true
            flashButton.layer.cornerRadius = 32
        }
    }
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var qrCodeFrameView: UIView!
    private var flashToggled = false
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    private var prevTintColor: UIColor?
    private var dissappeared = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prevTintColor = navigationController?.navigationBar.tintColor
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backButtonDisplayMode = .minimal

        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        setupCamera()
        self.title = "Scan Code"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.global(qos: .background).async {
            if (self.captureSession?.isRunning == false) {
                self.captureSession.startRunning()
            }
        }
        if dissappeared {
            dissappeared = false
            navigationController?.navigationBar.tintColor = .white
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
        navigationController?.navigationBar.tintColor = prevTintColor
        dissappeared = true
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr, .ean13]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        containerView.layer.insertSublayer(previewLayer, at: 0)

        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    private func failed() {
        let alertController = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
        captureSession = nil
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            let scanResult = found(code: stringValue)
            showResult(scanResult)
        } else {
            let alertController = UIAlertController(title: "Something went wrong", message: "Please, try again", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "TryAgain", style: .cancel))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
            present(alertController, animated: true)
        }
    }
    
    func showResult(_ result: QRCodeScanResult) {
        if hasSubscription {
            let desiredSize = CGSize(width: result.type == .barcode ? 216 : 147, height: 147)
            let codeImage = generateCode(from: result.rawCode, codeType: result.type, size: desiredSize) ?? UIImage()
            
            let resultVC = QRCodeResultViewController(scanResult: result, image: codeImage)
            navigationController?.pushViewController(resultVC, animated: true)
        } else {
            let vc = OnboardingViewController(pages: [.buy])
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }

    func found(code: String) -> QRCodeScanResult {
        print(code)
        let parsedInfo = QRCodeParser.parseQRCode(code)
        
        return QRCodeScanResult(type: parsedInfo.type, data: parsedInfo.parsedData, rawCode: parsedInfo.rawString, displayOrder: parsedInfo.type.defaultDisplayOrder)
    }

    private func generateCode(from string: String, codeType: QRCodeResultType, size: CGSize) -> UIImage? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        var filterName: String
        
        switch codeType {
        case .barcode:
            filterName = "CICode128BarcodeGenerator"
        case .url, .text, .email, .message, .contact, .wifi, .location, .unknown:
            if let data = QRGenerator.shared.generateQRCode(from: string, backgroundColor: .white, foregroundColor: .black, padding: 10) {
                return UIImage(data: data)
            }
            filterName = "CIQRCodeGenerator"
        }
        
        if let filter = CIFilter(name: filterName) {
            filter.setValue(data, forKey: "inputMessage")
            if codeType != .barcode {
                filter.setValue("H", forKey: "inputCorrectionLevel")
            }
            
            if let outputImage = filter.outputImage {
                var extent = outputImage.extent
                let scale: CGFloat
                var transformedImage: CIImage
                
                if codeType == .barcode {
                    // For barcode, make sure the image is exactly the size specified
                    let widthScale = size.width / extent.width
                    let heightScale = size.height / extent.height
                    scale = min(widthScale, heightScale)
                    transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: widthScale, y: heightScale))
                } else {
                    let padding: CGFloat = 3
                    extent = outputImage.extent.insetBy(dx: -padding, dy: -padding)
                    scale = min(size.width / extent.width, size.height / extent.height)
                    
                    transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                }

                let context = CIContext()
                if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        return nil
    }
    
    @IBAction
    private func openPhotoLibrary() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    
    private func detectQRCode(in image: UIImage) -> String? {
        if hasSubscription {
            return nil
        } else {
            guard let ciImage = CIImage(image: image) else { return nil }
            
            let context = CIContext()
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
            let features = detector?.features(in: ciImage) as? [CIQRCodeFeature]
            
            return features?.first?.messageString
        }
    }
    
    @IBAction
    private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        flashToggled.toggle()
        
        let name = flashToggled ? "bolt.fill" : "bolt.slash.fill"
        flashButton.setImage(UIImage(systemName: name), for: .normal)
        
        if flashToggled {
            flashButton.backgroundColor = R.color.ffcd34()
            flashButton.tintColor = .black
        } else {
            flashButton.configuration = .gray()
            flashButton.backgroundColor = nil
            flashButton.tintColor = .white
        }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if device.torchMode == .off {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
}

extension QRCodeScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            guard let code = detectQRCode(in: selectedImage) else {
                return
            }
            let scanResult = found(code: code)
            showResult(scanResult)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
