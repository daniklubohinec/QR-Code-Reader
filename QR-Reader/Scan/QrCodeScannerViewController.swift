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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prevTintColor = navigationController?.navigationBar.tintColor
        navigationItem.largeTitleDisplayMode = .never

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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
        navigationController?.navigationBar.tintColor = prevTintColor
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
            metadataOutput.metadataObjectTypes = [.qr]
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
            found(code: stringValue)
        }

        dismiss(animated: true)
    }

    func found(code: String) {
        print(code)
    }

    
    
    @IBAction
    private func openPhotoLibrary() {
        // Your code to open the photo library
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
