import Foundation
import CoreImage
import UIKit

final class QRGenerator {
    static let shared = QRGenerator()
    private let ciContext = CIContext()

    private init() { }

    func getQRDate(from qrCodeType: QRCodeType) -> Data {
        let text: String
        let backgroundColorHex: String?
        let foregroundColorHex: String?
        
        switch qrCodeType {
        case .wifi(let model):
            text = "WIFI:T:\(model?.type.rawValue ?? "WPA");S:\(model?.name ?? "");P:\(model?.password ?? "");;"
            backgroundColorHex = model?.backgroundHexColor
            foregroundColorHex = model?.foregroundHexColor
        case .url(let model):
            text = model?.url ?? ""
            backgroundColorHex = model?.backgroundHexColor
            foregroundColorHex = model?.foregroundHexColor
        case .text(let model):
            text = model?.text ?? ""
            backgroundColorHex = model?.backgroundHexColor
            foregroundColorHex = model?.foregroundHexColor
        case .contact(let model):
            let vCardComponents = [
                "BEGIN:VCARD",
                "VERSION:3.0",
                "N:\(model?.name ?? "")",
                "TEL:\(model?.phone ?? "")",
                "EMAIL:\(model?.mail ?? "")",
                "URL:\(model?.url ?? "")",
                "END:VCARD"
            ]
            text = vCardComponents.joined(separator: "\n")
            backgroundColorHex = model?.backgroundHexColor
            foregroundColorHex = model?.foregroundHexColor
        }
        lazy var backgroundColor: UIColor = {
            if let backgroundColorHex {
                return UIColor.colorWithHexString(hexString: backgroundColorHex)
            }
            return .white
        }()
        lazy var foregroundColor: UIColor = {
            if let foregroundColorHex {
                return UIColor.colorWithHexString(hexString: foregroundColorHex)
            }
            return .black
        }()
        
        return generateQRCode(from: text, backgroundColor: backgroundColor, foregroundColor: foregroundColor) ?? Data()
    }
    
    func generateQRCode(from string: String, backgroundColor: UIColor, foregroundColor: UIColor) -> Data? {
        guard let data = string.data(using: .ascii) else { return nil }
        
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let qrImage = qrFilter.outputImage else { return nil }
        
        let padding: CGFloat = 3
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
