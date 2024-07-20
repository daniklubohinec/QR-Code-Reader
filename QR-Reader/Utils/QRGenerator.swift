import Foundation
import CoreImage
import UIKit

final class QRGenerator {
    static let shared = QRGenerator()
    private let ciContext = CIContext()

    private init() { }

    func getQRDate(from qrCodeData: QRCodeData) -> Data {
        let text: String
        
        switch qrCodeData.type {
        case .wifi:
            text = "WIFI:T:\(qrCodeData.data["Type"] ?? "WPA");S:\(qrCodeData.data["WiFi Name"] ?? "");P:\(qrCodeData.data["Password"] ?? "");;"
        case .url:
            text = qrCodeData.data["URL"] ?? ""
        case .text:
            text = qrCodeData.data["Text"] ?? ""
        case .contact:
            let vCardComponents = [
                "BEGIN:VCARD",
                "VERSION:3.0",
                "N:\(qrCodeData.data["Contact Name"] ?? "")",
                "TEL:\(qrCodeData.data["Phone Number"] ?? "")",
                "EMAIL:\(qrCodeData.data["Mail"] ?? "")",
                "URL:\(qrCodeData.data["URL"] ?? "")",
                "END:VCARD"
            ]
            text = vCardComponents.joined(separator: "\n")
        }
        lazy var backgroundColor: UIColor = {
            if let backgroundColorHex = qrCodeData.backgroundHexColor {
                return UIColor.colorWithHexString(hexString: backgroundColorHex)
            }
            return .white
        }()
        lazy var foregroundColor: UIColor = {
            if let foregroundColorHex = qrCodeData.foregroundHexColor {
                return UIColor.colorWithHexString(hexString: foregroundColorHex)
            }
            return .black
        }()
        
        return generateQRCode(from: text, backgroundColor: backgroundColor, foregroundColor: foregroundColor) ?? Data()
    }
    
    func generateQRCode(from string: String, backgroundColor: UIColor, foregroundColor: UIColor, padding: CGFloat = 3) -> Data? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let qrImage = qrFilter.outputImage else { return nil }
        
        let extent = qrImage.extent.insetBy(dx: -padding, dy: -padding)
        
        let backgroundImage = CIImage(color: CIColor(color: backgroundColor))
            .cropped(to: extent)
        
        let coloredQR = qrImage.applyingFilter("CIFalseColor", parameters: [
            "inputColor0": CIColor(color: foregroundColor),
            "inputColor1": CIColor(color: .clear)
        ])
        
        let finalImage = coloredQR.composited(over: backgroundImage)
        
        let scale: CGFloat = 10
        let scaledImage = finalImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = ciContext.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage).pngData()
    }
}
