import Foundation
import UIKit

struct QRDataProcessor {
    private let qrCodeType: QRCodeType
    var wifiModel: WifiQRModel?
    var textModel: TextQRModel?
    var urlModel: URLQRModel?
    var contactModel: ContactQRModel?
    
    var backgroundColor: UIColor? {
        didSet {
            wifiModel?.backgroundHexColor = backgroundColor?.hexStringFromColor()
            textModel?.backgroundHexColor = backgroundColor?.hexStringFromColor()
            urlModel?.backgroundHexColor = backgroundColor?.hexStringFromColor()
            contactModel?.backgroundHexColor = backgroundColor?.hexStringFromColor()
        }
    }
    var foregroundColor: UIColor? {
        didSet {
            wifiModel?.foregroundHexColor = foregroundColor?.hexStringFromColor()
            textModel?.foregroundHexColor = foregroundColor?.hexStringFromColor()
            urlModel?.foregroundHexColor = foregroundColor?.hexStringFromColor()
            contactModel?.foregroundHexColor = foregroundColor?.hexStringFromColor()
        }
    }
    
    init(from qrCodeType: QRCodeType) {
        self.qrCodeType = qrCodeType
        switch qrCodeType {
        case .text(let textQRModel):
            self.textModel = textQRModel
        case .wifi(let wifiQRModel):
            self.wifiModel = wifiQRModel
        case .url(let urlQRModel):
            self.urlModel = urlQRModel
        case .contact(let contactQRModel):
            self.contactModel = contactQRModel
        }
    }
    
    func save() {
        let name: String? = {
            if let wifiModel {
                return wifiModel.name
            }
            if let textModel {
                return textModel.text
            }
            if let urlModel {
                return urlModel.url
            }
            if let contactModel {
                return contactModel.name
            }
            return nil
        }()
        let updatedType: QRCodeType = {
            switch qrCodeType {
            case .text:
                return .text(textModel)
            case .wifi:
                return .wifi(wifiModel)
            case .url:
                return .url(urlModel)
            case .contact:
                return .contact(contactModel)
            }
        }()
        guard let name else { return }
        let item = HistoryItem(qrCodeType: updatedType, name: name, itemType: .created, date: Date())
        DispatchQueue.global(qos: .background).async {
            var currentItems: [HistoryItem] = Storage.shared.stored(at: StorageKey.historyList.rawValue) ?? []
            currentItems.append(item)
            Storage.shared.store(value: currentItems, at: StorageKey.historyList.rawValue)
        }
    }
    
    func saveChanges(item: HistoryItem) {
        let updatedType: QRCodeType = {
            switch qrCodeType {
            case .text:
                return .text(textModel)
            case .wifi:
                return .wifi(wifiModel)
            case .url:
                return .url(urlModel)
            case .contact:
                return .contact(contactModel)
            }
        }()
        let name: String? = {
            if let wifiModel {
                return wifiModel.name
            }
            if let textModel {
                return textModel.text
            }
            if let urlModel {
                return urlModel.url
            }
            if let contactModel {
                return contactModel.name
            }
            return nil
        }()
        guard let name else { return }

        let item = HistoryItem(id: item.id, qrCodeType: updatedType, name: name, itemType: .created, date: Date())

        DispatchQueue.global(qos: .background).async {
            var currentItems: [HistoryItem] = Storage.shared.stored(at: StorageKey.historyList.rawValue) ?? []
            currentItems.removeAll(where: { $0.id == item.id })
            currentItems.append(item)
            Storage.shared.store(value: currentItems, at: StorageKey.historyList.rawValue)
        }
    }
    
    func saveAsCopy(item: HistoryItem) {
        let updatedType: QRCodeType = {
            switch qrCodeType {
            case .text:
                return .text(textModel)
            case .wifi:
                return .wifi(wifiModel)
            case .url:
                return .url(urlModel)
            case .contact:
                return .contact(contactModel)
            }
        }()
        let name: String? = {
            if let wifiModel {
                return wifiModel.name
            }
            if let textModel {
                return textModel.text
            }
            if let urlModel {
                return urlModel.url
            }
            if let contactModel {
                return contactModel.name
            }
            return nil
        }()
        guard let name else { return }
        let item = HistoryItem(qrCodeType: updatedType, name: name, itemType: .created, date: Date())

        DispatchQueue.global(qos: .background).async {
            var currentItems: [HistoryItem] = Storage.shared.stored(at: StorageKey.historyList.rawValue) ?? []
            currentItems.append(item)
            Storage.shared.store(value: currentItems, at: StorageKey.historyList.rawValue)
        }
    }
}
