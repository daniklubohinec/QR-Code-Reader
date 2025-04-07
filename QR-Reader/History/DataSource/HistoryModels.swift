import Foundation
import UIKit

enum WifiType: String, CaseIterable, Codable {
    case wpa = "WPA"
    case wep = "WEP"
    case free = "FREE"
}

struct QRCodeData: Codable, Equatable {
    enum QRCodeType: String, Codable {
        case wifi, url, text, contact
        
        var createTitle: String {
            switch self {
            case .wifi:
                return "Create WiFi"
            case .url:
                return "Create URL"
            case .text:
                return "Create Text"
            case .contact:
                return "Create Contact"
            }
        }
        
        var name: String {
            switch self {
            case .wifi:
                return "WiFi"
            case .url:
                return "URL"
            case .text:
                return "Text"
            case .contact:
                return "Contact"
            }
        }
    }
    
    let type: QRCodeType
    var data: [String: String]
    var backgroundHexColor: String?
    var foregroundHexColor: String?
    var inputFields: [Field] {
        switch type {
        case .wifi:
            return [
                Field(
                    fieldType: .networkName,
                    title: "WiFi Name",
                    placeholder: "Enter network name",
                    value: data["WiFi Name"]
                ),
                Field(
                    fieldType: .networkPassword,
                    title: "Password",
                    placeholder: "Enter password",
                    value: data["Password"]
                )
            ]
        case .url:
            return [
                Field(
                    fieldType: .url,
                    title: "URL",
                    placeholder: "Enter link",
                    value: data["URL"]
                )
            ]
        case .text:
            return [
                Field(
                    fieldType: .text,
                    title: "Text",
                    placeholder: "Enter text",
                    value: data["Text"]
                )
            ]
        case .contact:
            return [
                Field(
                    fieldType: .contactName,
                    title: "Contact Name",
                    placeholder: "Enter contact name",
                    value: data["Contact Name"]
                ),
                Field(
                    fieldType: .contactNumber,
                    title: "Phone Number",
                    placeholder: "Enter phone number",
                    value: data["Phone Number"]
                ),
                Field(
                    fieldType: .contactMail,
                    title: "Mail",
                    placeholder: "Enter contact mail",
                    value: data["Mail"]
                ),
                Field(
                    fieldType: .contactURL,
                    title: "URL",
                    placeholder: "Enter contact URL",
                    value: data["URL"]
                )
            ]
        }
    }
}
struct CreatedQRCodeItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let qrCodeData: QRCodeData
    let date: Date
    
    var name: String {
        switch qrCodeData.type {
        case .wifi:
            return qrCodeData.data["WiFi Name"] ?? qrCodeData.type.rawValue
        case .url:
            return qrCodeData.data["URL"] ?? qrCodeData.type.rawValue
        case .text:
            return qrCodeData.data["Text"] ?? qrCodeData.type.rawValue
        case .contact:
            return qrCodeData.data["Contact Name"] ?? qrCodeData.type.rawValue
        }
    }
    
    var qrCodeImageData: Data {
        return QRGenerator.shared.getQRDate(from: qrCodeData)
    }
}
struct HistoryItem: Identifiable, Codable, Equatable {
    enum ItemType: Int, Codable {
        case scanned, created
    }
    
    enum Item: Codable, Equatable {
        case scanned(QRCodeScanResult)
        case created(CreatedQRCodeItem)
        
        var qrCodeImageData: Data {
            switch self {
            case .scanned(let result):
                return QRGenerator.shared.generateQRCode(from: result.rawCode, backgroundColor: .black, foregroundColor: .white) ?? Data()
            case .created(let createdQRCodeItem):
                return QRGenerator.shared.getQRDate(from: createdQRCodeItem.qrCodeData)
            }
        }
        var name: String {
            switch self {
            case .scanned(let result):
                return result.name
            case .created(let createdQRCodeItem):
                return createdQRCodeItem.name
            }
        }
    }
    var id: UUID = UUID()
    let item: Item
    let date: Date
    var itemType: ItemType {
        switch item {
        case .scanned:
            return .scanned
        case .created:
            return .created
        }
    }
    var scanResult: QRCodeScanResult? {
        switch item {
        case .scanned(let result):
            return result
        case .created:
            return nil
        }
    }
    var qrCodeData: QRCodeData? {
        switch item {
        case .scanned:
            return nil
        case .created(let createdQRCodeItem):
            return createdQRCodeItem.qrCodeData
        }
    }
    var typeName: String {
        switch item {
        case .scanned(let result):
            return result.type.name
        case .created(let createdQRCodeItem):
            return createdQRCodeItem.qrCodeData.type.name
        }
    }
    
    var name: String {
        item.name
    }
    
    var qrCodeImageData: Data {
        return item.qrCodeImageData
    }
}

struct HistoryList {
    static let empty = HistoryList(scanned: .init(entries: []), created: .init(entries: [])
    )
    let scanned: HistoryListModel
    let created: HistoryListModel
    
    var isEmpty: Bool {
        return scanned.entries.isEmpty && created.entries.isEmpty
    }
    
    func updateWithScanned(_ item: HistoryItem) -> HistoryList {
        return HistoryList(scanned: scanned.updateWith(item), created: created)
    }
    
    func updateWithCreated(_ item: HistoryItem) -> HistoryList {
        return HistoryList(scanned: scanned, created: created.updateWith(item))
    }
}

struct HistoryListModel: Equatable {
    let entries: [DateSection]
    
    func updateWith(_ item: HistoryItem) -> HistoryListModel {
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
