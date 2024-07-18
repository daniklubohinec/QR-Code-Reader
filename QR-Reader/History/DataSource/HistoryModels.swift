import Foundation
import UIKit

typealias QRDataModel = Codable & Equatable & Hashable

struct WifiQRModel: QRDataModel {
    static let empty = Self(type: .wpa, name: "", password: "", backgroundHexColor: nil, foregroundHexColor: nil)
    
    enum WifiType: String, CaseIterable, Codable {
        case wpa = "WPA"
        case wep = "WEP"
        case free = ""
    }
    var type: WifiType
    var name: String
    var password: String
    var backgroundHexColor: String?
    var foregroundHexColor: String?
}

struct URLQRModel: QRDataModel {
    static let empty = Self(url: "", backgroundHexColor: nil, foregroundHexColor: nil)
    
    var url: String
    var backgroundHexColor: String?
    var foregroundHexColor: String?
}

struct TextQRModel: QRDataModel {
    static let empty = Self(text: "", backgroundHexColor: nil, foregroundHexColor: nil)
    
    var text: String
    var backgroundHexColor: String?
    var foregroundHexColor: String?
}

struct ContactQRModel: QRDataModel {
    static let empty = Self(name: "", phone: "", mail: "", url: "", backgroundHexColor: nil, foregroundHexColor: nil)

    var name: String
    var phone: String
    var mail: String
    var url: String
    var backgroundHexColor: String?
    var foregroundHexColor: String?
}

struct HistoryItem: Identifiable, Codable, Equatable, Hashable {
    enum ItemType: Codable, Equatable {
        case scanned
        case created
    }
    
    var id: UUID = UUID()
    let qrCodeType: QRCodeType
    let name: String
    let itemType: ItemType
    let date: Date
    
    // Генерация данных для QR-кода из qrCodeType
    var qrImageData: Data {
        return QRGenerator.getQRDate(from: qrCodeType)
    }
}

struct HistoryList {
    static let empty = HistoryList(scanned: .init(entries: []), created: .init(entries: []))
    let scanned: ScannedHistoryListModel
    let created: CreatedHistoryListModel
    
    var isEmpty: Bool {
        return scanned.entries.isEmpty && created.entries.isEmpty
    }
    
    func updateWithScanned(list: ScannedHistoryListModel) -> Self {
        return Self(scanned: list, created: created)
    }
    
    func updateWithCreated(list: CreatedHistoryListModel) -> Self {
        return Self(scanned: scanned, created: list)
    }
}

struct DateSection: Equatable {
    let date: Date
    var items: [HistoryItem]
}

protocol HistoryUpdatableList {
    func updateWith(_ item: HistoryItem) -> Self
}

struct ScannedHistoryListModel: Equatable, HistoryUpdatableList {
    let entries: [DateSection]
    
    func updateWith(_ item: HistoryItem) -> ScannedHistoryListModel {
        var updatedEntries = self.entries
        let itemDate = Calendar.current.startOfDay(for: item.date)
        
        if let index = updatedEntries.firstIndex(where: { $0.date == itemDate }) {
            updatedEntries[index] = DateSection(date: itemDate, items: [item] + updatedEntries[index].items)
        } else {
            let newSection = DateSection(date: itemDate, items: [item])
            updatedEntries.insert(newSection, at: 0)
        }
        
        return Self(entries: updatedEntries)
    }
}

struct CreatedHistoryListModel: Equatable, HistoryUpdatableList {
    let entries: [DateSection]
    
    func updateWith(_ item: HistoryItem) -> CreatedHistoryListModel {
        var updatedEntries = self.entries
        let itemDate = Calendar.current.startOfDay(for: item.date)
        
        if let index = updatedEntries.firstIndex(where: { $0.date == itemDate }) {
            updatedEntries[index] = DateSection(date: itemDate, items: [item] + updatedEntries[index].items)
        } else {
            let newSection = DateSection(date: itemDate, items: [item])
            updatedEntries.insert(newSection, at: 0)
        }
        
        return Self(entries: updatedEntries)
    }
}
