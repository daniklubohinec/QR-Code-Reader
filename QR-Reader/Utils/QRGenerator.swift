import Foundation
import CoreImage
import UIKit

struct QRGenerator {
    private init() { }
    static func getQRDate(from qrCodeType: QRCodeType) -> Data {
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
            text = """
            BEGIN:VCARD
            VERSION:3.0
            N:\(model?.name ?? "")
            TEL:\(model?.phone ?? "")
            EMAIL:\(model?.mail ?? "")
            URL:\(model?.url ?? "")
            END:VCARD
            """
            
            backgroundColorHex = model?.backgroundHexColor
            foregroundColorHex = model?.foregroundHexColor
        }
        let backgroundColor: UIColor = {
            if let backgroundColorHex {
                return UIColor.colorWithHexString(hexString: backgroundColorHex)
            }
            return .white
        }()
        let foregroundColor: UIColor = {
            if let foregroundColorHex {
                return UIColor.colorWithHexString(hexString: foregroundColorHex)
            }
            return .black
        }()
        
        return generateQRCode(from: text, backgroundColor: backgroundColor, foregroundColor: foregroundColor) ?? Data()
    }
    
    static func generateQRCode(from string: String, backgroundColor: UIColor, foregroundColor: UIColor) -> Data? {
        guard let data = string.data(using: .ascii) else { return nil }
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")

            if let outputImage = filter.outputImage {
                let colorFilter = CIFilter(name: "CIFalseColor")
                colorFilter?.setValue(outputImage, forKey: "inputImage")
                colorFilter?.setValue(CIColor(color: foregroundColor), forKey: "inputColor0")
                colorFilter?.setValue(CIColor(color: backgroundColor), forKey: "inputColor1")
                
                if let coloredImage = colorFilter?.outputImage {
                    let transform = CGAffineTransform(scaleX: 10, y: 10)
                    let scaledImage = coloredImage.transformed(by: transform)
                    
                    return UIImage(ciImage: scaledImage).pngData()
                }
            }
        }
        
        return nil
    }
}
