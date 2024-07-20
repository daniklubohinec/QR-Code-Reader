import Foundation
import RxRelay
import RxSwift

enum StorageKey: String {
    case historyList
}

final class HistoryViewModel {
    private let queue = DispatchQueue(label: String(describing: HistoryViewModel.self))
    var historyListRelay: BehaviorRelay<HistoryList> = .init(value: .init(scanned: .init(entries: []), created: .init(entries: [])))
    let selectedSegmentIndex = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()
    
    var currentSections: Observable<[DateSection]> {
        return Observable.combineLatest(historyListRelay, selectedSegmentIndex)
            .map { historyList, index in
                index == 0 ? historyList.scanned.entries : historyList.created.entries
            }
    }

    init() {
        queue.async { [weak self] in
            self?.loadData()
        }
    }
    
    private func loadData() {
        Storage.shared.observable(for: StorageKey.historyList.rawValue)
            .subscribe(onNext: { [weak self] (items: [HistoryItem]?) in
                guard let items = items else { return }
                self?.processLoadedItems(items)
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
