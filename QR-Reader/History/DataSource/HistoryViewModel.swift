import Foundation
import RxRelay
import RxSwift

enum StorageKey: String {
    case historyList
}

final class HistoryViewModel {
    private let queue = DispatchQueue(label: String(describing: HistoryViewModel.self))
    var historyListRelay: BehaviorRelay<HistoryList> = .init(value: .empty)
    let selectedSegmentIndex = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()
    
    var currentSections: Observable<[DateSection]> {
        return Observable.combineLatest(historyListRelay, selectedSegmentIndex)
            .map { historyList, index in
                index == 0 ? historyList.scanned.entries : historyList.created.entries
            }
    }

    init(useMocks: Bool = false) {
        if useMocks {
            let mocks = HistoryViewModel.generateMockData()
            Storage.shared.store(value: mocks, at: StorageKey.historyList.rawValue)
            processLoadedItems(mocks)
        } else {
            queue.async { [weak self] in
                self?.loadData()
            }
        }
    }
    
    private func loadData() {
        Storage.shared.observable(for: StorageKey.historyList.rawValue)
            .subscribe(onNext: { [weak self] (items: [HistoryItem]?) in
                guard let items = items else { return }
                let set = Set<HistoryItem>(items)
                self?.processLoadedItems(Array(set))
            })
            .disposed(by: disposeBag)
    }
    
    private func processLoadedItems(_ items: [HistoryItem]) {
        let historyList = HistoryList(
            scanned: .init(entries: groupAndSortByDate(items.filter { $0.itemType == .scanned })),
            created: .init(entries: groupAndSortByDate(items.filter { $0.itemType == .created }))
        )
        historyListRelay.accept(historyList)
    }
    
    private func groupAndSortByDate(_ items: [HistoryItem]) -> [DateSection] {
        let groupedItems = Dictionary(grouping: items) { item in
            Calendar.current.startOfDay(for: item.date)
        }
        
        return groupedItems.map { (date, items) in
            DateSection(date: date, items: items.sorted(by: { $0.date > $1.date }))
        }.sorted(by: { $0.date > $1.date })
    }
    
    func addItem(_ item: HistoryItem) {
        queue.async { [weak self] in
            var items: [HistoryItem] = Storage.shared.stored(at: StorageKey.historyList.rawValue) ?? []
            items.append(item)
            Storage.shared.store(value: items, at: StorageKey.historyList.rawValue)
            self?.processLoadedItems(items)
        }
    }
    
    func removeItem(_ item: HistoryItem) {
        var items: [HistoryItem] = Storage.shared.stored(at: StorageKey.historyList.rawValue) ?? []
        items.removeAll { $0.id == item.id }
        Storage.shared.store(value: items, at: StorageKey.historyList.rawValue)
        processLoadedItems(items)
    }
    
    func removeAll() {
        queue.async { [weak self] in
            guard let self else { return }
            let selectedSegment = selectedSegmentIndex.value
            var items: [HistoryItem] = Storage.shared.stored(at: StorageKey.historyList.rawValue) ?? []
            items = items.filter({ $0.itemType.rawValue != selectedSegment })
            Storage.shared.store(value: items, at: StorageKey.historyList.rawValue)
            processLoadedItems(items)
        }
    }
}

extension HistoryViewModel {
    static func generateMockData() -> [HistoryItem] {
        let currentDate = Date()
        let calendar = Calendar.current
        
        let mockItems: [HistoryItem] = [
            HistoryItem(id: UUID(), qrCodeType: .contact(ContactQRModel(name: "John Doe", phone: "123456789", mail: "john.doe@example.com", url: "https://example.com", backgroundHexColor: nil, foregroundHexColor: nil)), name: "John Doe", itemType: .scanned, date: calendar.date(byAdding: .day, value: -1, to: currentDate)!),
            HistoryItem(id: UUID(), qrCodeType: .url(URLQRModel(url: "https://www.example.com", backgroundHexColor: nil, foregroundHexColor: nil)), name: "https://www.example.com", itemType: .created, date: calendar.date(byAdding: .day, value: -1, to: currentDate)!),
            HistoryItem(id: UUID(), qrCodeType: .wifi(WifiQRModel(type: .wep, name: "Home WiFi", password: "password123", backgroundHexColor: nil, foregroundHexColor: nil)), name: "Home WiFi", itemType: .scanned, date: calendar.date(byAdding: .day, value: -2, to: currentDate)!),
            HistoryItem(id: UUID(), qrCodeType: .text(TextQRModel(text: "Remember to buy milk", backgroundHexColor: "#007AFF", foregroundHexColor: "#0F0E13")), name: "Remember to buy milk", itemType: .created, date: calendar.date(byAdding: .day, value: -2, to: currentDate)!),
            HistoryItem(id: UUID(), qrCodeType: .contact(ContactQRModel(name: "Jane Smith", phone: "987654321", mail: "jane.smith@example.com", url: "https://example.com", backgroundHexColor: nil, foregroundHexColor: nil)), name: "Jane Smith", itemType: .scanned, date: calendar.date(byAdding: .day, value: -3, to: currentDate)!),
            HistoryItem(id: UUID(), qrCodeType: .url(URLQRModel(url: "https://www.github.com", backgroundHexColor: nil, foregroundHexColor: nil)), name: "https://www.github.com", itemType: .created, date: calendar.date(byAdding: .day, value: -4, to: currentDate)!),
            HistoryItem(id: UUID(), qrCodeType: .wifi(WifiQRModel(type: .wpa, name: "Office WiFi", password: "officepassword", backgroundHexColor: nil, foregroundHexColor: nil)), name: "Office WiFi", itemType: .scanned, date: calendar.date(byAdding: .day, value: -5, to: currentDate)!),
            HistoryItem(id: UUID(), qrCodeType: .text(TextQRModel(text: "Meeting at 3 PM", backgroundHexColor: "#FFCC00", foregroundHexColor: "#FF3B30")), name: "Meeting at 3 PM", itemType: .created, date: calendar.date(byAdding: .day, value: -5, to: currentDate)!),
            HistoryItem(id: UUID(), qrCodeType: .contact(ContactQRModel(name: "Alice Johnson", phone: "555666777", mail: "alice.johnson@example.com", url: "https://example.com", backgroundHexColor: nil, foregroundHexColor: nil)), name: "Alice Johnson", itemType: .scanned, date: calendar.date(byAdding: .day, value: -6, to: currentDate)!),
            HistoryItem(id: UUID(), qrCodeType: .url(URLQRModel(url: "https://www.apple.com", backgroundHexColor: nil, foregroundHexColor: nil)), name: "https://www.apple.com", itemType: .created, date: calendar.date(byAdding: .day, value: -7, to: currentDate)!)
        ]
        
        return mockItems
    }
}
