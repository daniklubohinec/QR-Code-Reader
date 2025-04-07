import Foundation
import UIKit

final class QRDataProcessor {
    private let queue = DispatchQueue(label: String(describing: QRDataProcessor.self))
    private var savedData: QRCodeData?
    
    init() { }
    
    func saveScanResult(result: QRCodeScanResult) {
        let item = HistoryItem(item: .scanned(result), date: Date())
        
        queue.async {
            var currentItems: [HistoryItem] = Storage.shared.stored(at: StorageKey.historyList.rawValue) ?? []
            currentItems.append(item)
            Storage.shared.store(value: currentItems, at: StorageKey.historyList.rawValue)
        }
    }
    
    func save(qrCodeData: QRCodeData) {
        if let savedData = savedData, savedData == qrCodeData {
            return
        }
        let item = HistoryItem(item: .created(CreatedQRCodeItem(qrCodeData: qrCodeData, date: Date())), date: Date())
       
        queue.async { [weak self] in
            var currentItems: [HistoryItem] = Storage.shared.stored(at: StorageKey.historyList.rawValue) ?? []
            currentItems.append(item)
            Storage.shared.store(value: currentItems, at: StorageKey.historyList.rawValue)
            self?.savedData = qrCodeData
        }
    }
    
    func saveChanges(item: HistoryItem, modifiedData: QRCodeData) {
        let item = HistoryItem(id: item.id, item: .created(.init(qrCodeData: modifiedData, date: item.date)), date: Date())
        
        queue.async {
            var currentItems: [HistoryItem] = Storage.shared.stored(at: StorageKey.historyList.rawValue) ?? []
            currentItems.removeAll(where: { $0.id == item.id })
            currentItems.append(item)
            Storage.shared.store(value: currentItems, at: StorageKey.historyList.rawValue)
        }
    }
    
    func saveAsCopy(item: HistoryItem, modifiedData: QRCodeData) {
        let item = HistoryItem(item: .created(CreatedQRCodeItem(qrCodeData: modifiedData, date: Date())), date: Date())
        
        queue.async {
            var currentItems: [HistoryItem] = Storage.shared.stored(at: StorageKey.historyList.rawValue) ?? []
            currentItems.append(item)
            Storage.shared.store(value: currentItems, at: StorageKey.historyList.rawValue)
        }
    }
}
