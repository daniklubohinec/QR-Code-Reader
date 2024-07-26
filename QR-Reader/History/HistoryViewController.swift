import Foundation
import UIKit
import Photos
import RxSwift
import RxCocoa
import RxDataSources

final class HistoryViewController: UIViewController {
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = R.font.interBold(size: 24)
            titleLabel.textColor = R.color.c030303()
        }
    }
    @IBOutlet weak var textLabel: UILabel! {
        didSet {
            textLabel.font = R.font.interRegular(size: 15)
            textLabel.textColor = R.color.c030303()
        }
    }
    @IBOutlet weak var actionButton: UIButton! {
        didSet {
            actionButton.clipsToBounds = true
            actionButton.layer.cornerRadius = 15.0
        }
    }
    
    var viewModel: HistoryViewModel!
    private let disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<DateSection>!
    private var currentSegmentIndex = 0
    private var scannedEmpty = false
    private var createdEmpty = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        title = "History"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.trash(), style: .plain, target: self, action: #selector(trashTapped))
        navigationItem.rightBarButtonItem?.tintColor = R.color.fe4848()
        
        tableView.delegate = self
        tableView.register(CustomHeaderView.self, forHeaderFooterViewReuseIdentifier: CustomHeaderView.reuseIdentifier)
        tableView.register(HistoryItemTableViewCell.self, forCellReuseIdentifier: HistoryItemTableViewCell.reuseIdentifier)
        tableView.backgroundColor = R.color.cF1F1F1()
        configureEmptyView()
    }
    
    private func bindViewModel() {
        segmentedControl.rx.selectedSegmentIndex
            .bind(to: viewModel.selectedSegmentIndex)
            .disposed(by: disposeBag)
        segmentedControl.rx.selectedSegmentIndex
            .changed
            .subscribe(onNext: { [weak self] value in
                guard let self else { return }
                HapticGenerator.shared.generateImpact()
                currentSegmentIndex = value
                configureEmptyView()
                if value == 0 {
                    tableView.isHidden = scannedEmpty
                    emptyView.isHidden = !scannedEmpty
                } else {
                    tableView.isHidden = createdEmpty
                    emptyView.isHidden = !createdEmpty
                }
                
            })
            .disposed(by: disposeBag)
        
        // Bind table view data
        dataSource = RxTableViewSectionedReloadDataSource<DateSection>(
            configureCell: { (_, tableView, indexPath, item) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: HistoryItemTableViewCell.reuseIdentifier, for: indexPath) as! HistoryItemTableViewCell
                cell.configure(with: item)
                return cell
            }
        )
        
        viewModel.currentSections
                    .bind(to: tableView.rx.items(dataSource: dataSource))
                    .disposed(by: disposeBag)
        
        viewModel.historyListRelay
            .asObservable()
            .subscribe(onNext: { [weak self] list in
                self?.scannedEmpty = list.scanned.entries.isEmpty
                self?.createdEmpty = list.created.entries.isEmpty
                onMain {
                    if self?.segmentedControl.selectedSegmentIndex == 0 {
                        self?.tableView.isHidden = list.scanned.entries.isEmpty
                        self?.emptyView.isHidden = !list.scanned.entries.isEmpty
                    }
                }
            })
            .disposed(by: disposeBag)
        
        // Handle item selection
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self else { return }
                tableView.deselectRow(at: indexPath, animated: true)
                let item = dataSource[indexPath]
                openDetail(item: item)
            })
            .disposed(by: disposeBag)
        
        // Handle item deletion
        tableView.rx.itemDeleted
            .subscribe(onNext: { [weak self] indexPath in
                guard let self else { return }
                let item = dataSource[indexPath]
                viewModel.removeItem(item)
            })
            .disposed(by: disposeBag)
    }
    
    private func configureEmptyView() {
        let isScannedTab = currentSegmentIndex == 0
        self.titleLabel.text = isScannedTab ? "No Scanned Barcodes" : "No Created QR Codes"
        self.textLabel.text = isScannedTab ? "All the barcodes you've scanned will show up here." : "Your generated QR codes will be displayed here."
        var configuration = self.actionButton.configuration ?? .filled()
        configuration.baseBackgroundColor = R.color.accentColor()
        configuration.title = isScannedTab ? "Scan" : "Create QR"
        configuration.imagePlacement = .leading
        configuration.imagePadding = 8
        configuration.image = isScannedTab ? R.image.scanAction() : UIImage(systemName: "qrcode")
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { value in
            var value = value
            value.font = R.font.interMedium(size: 16)
            return value
        }
        self.actionButton.configuration = configuration
        self.actionButton.updateConfiguration()
    }
    
    @objc
    private func trashTapped() {
        deleteAll()
        HapticGenerator.shared.generateImpact()
    }
    
    @IBAction
    private func emptyAction() {
        HapticGenerator.shared.generateImpact()
        if currentSegmentIndex == 0 {
            guard let scannerVC = R.storyboard.qrCodeScanner.qrCodeScanner.callAsFunction() else { return }
            scannerVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(scannerVC, animated: true)
        } else {
            tabBarController?.selectedIndex = 0
        }
    }
    
    private func openDetail(item: HistoryItem) {
        HapticGenerator.shared.generateImpact()
        if segmentedControl.selectedSegmentIndex == 0 {
            guard let image = UIImage(data: item.qrCodeImageData), let result = item.scanResult else { return }
            let vc = QRCodeResultViewController(scanResult: result, image: image)
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        } else {
            guard let type = item.qrCodeData?.type else { return }
            let vc = QRCodeCreatorViewController(type: type, data: nil, item: item, state: .preview)
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: CustomHeaderView.reuseIdentifier) as! CustomHeaderView
        let sectionDate = dataSource[section].date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        headerView.titleLabel.text = dateFormatter.string(from: sectionDate)
        return headerView
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = (tableView.cellForRow(at: indexPath) as? HistoryItemTableViewCell)?.item else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            self?.deleteItem(item: item)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        
        let moreAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            self?.showMoreOptions(for: item)
            completion(true)
        }
        moreAction.image = UIImage(systemName: "ellipsis.circle.fill")
        
        return UISwipeActionsConfiguration(actions: [moreAction, deleteAction])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8.0
    }
}

// Extend DateSection to conform to SectionModelType for RxDataSources
extension DateSection: SectionModelType {
    typealias Item = HistoryItem
    
    init(original: DateSection, items: [HistoryItem]) {
        self = original
        self.items = items
    }
}

extension HistoryViewController {
    private func showMoreOptions(for item: HistoryItem) {
        let sheet = UIAlertController(title: item.name, message: nil, preferredStyle: .actionSheet)
        let copyAction = UIAlertAction(title: "Copy", style: .default) { _ in
            HapticGenerator.shared.generateImpact()
            UIPasteboard.general.image = UIImage(data: item.qrCodeImageData)
            ToastViewController.showToast(with: "Copied", with: "doc.on.doc")
        }
        let shareAction = UIAlertAction(title: "Share", style: .default) { [weak self] _ in
            guard let qrImage = UIImage(data: item.qrCodeImageData), let self else {
                return
            }
            HapticGenerator.shared.generateImpact()
            share(qrImage: qrImage, onViewController: self)
        }
        let saveAction = UIAlertAction(title: "Save as Image", style: .default) { _ in
            guard let qrImage = UIImage(data: item.qrCodeImageData) else {
                return
            }
            HapticGenerator.shared.generateImpact()
            saveToGallery(qrImage: qrImage)
        }
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            HapticGenerator.shared.generateImpact()
            self?.deleteItem(item: item)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        [copyAction, shareAction, saveAction, deleteAction, cancel].forEach { sheet.addAction($0) }
        present(sheet, animated: true)
    }
    
    private func deleteItem(item: HistoryItem) {
        let alert = UIAlertController(title: "Are you sure you want to delete this?", message: "This action cannot be undone.", preferredStyle: .alert)
        let delete = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            HapticGenerator.shared.generateImpact()
            self?.viewModel.removeItem(item)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancel)
        alert.addAction(delete)
        present(alert, animated: true)
    }
    
    private func deleteAll() {
        let alert = UIAlertController(title: "Are you sure you want to clear your history?", message: "This action cannot be undone.", preferredStyle: .alert)
        let delete = UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            HapticGenerator.shared.generateImpact()
            self?.viewModel.removeAll()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancel)
        alert.addAction(delete)
        present(alert, animated: true)
    }
}
