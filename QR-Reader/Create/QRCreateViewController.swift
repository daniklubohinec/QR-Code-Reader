import UIKit
import CoreImage
import Photos
import RxSwift

final class QRCodeCreatorViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case preview, wifiType, data, colors
    }
    enum State {
        case preview
        case editing
        case creating
    }
    
    private var qrCodeData: QRCodeData
    private var qrCodeImage: UIImage?
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = R.color.cF1F1F1()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(QRCodePreviewCell.self, forCellWithReuseIdentifier: QRCodePreviewCell.reuseIdentifier)
        collectionView.register(QRCodeWifiTypeCell.self, forCellWithReuseIdentifier: QRCodeWifiTypeCell.reuseIdentifier)
        collectionView.register(InputFieldCell.self, forCellWithReuseIdentifier: InputFieldCell.reuseIdentifier)
        collectionView.register(ColorPickerCell.self, forCellWithReuseIdentifier: ColorPickerCell.reuseIdentifier)
        return collectionView
    }()
    private lazy var qrCodeProcessor: QRDataProcessor = {
        return QRDataProcessor()
    }()
    private var selectedBackgroundColor: UIColor?
    private var selectedForegroundColor: UIColor?
    
    private let disposeBag = DisposeBag()
    private var appeared = false
    private let state: State
    private let item: HistoryItem?
    
    init(type: QRCodeData.QRCodeType, data: QRCodeData? = nil, item: HistoryItem? = nil, state: State) {
        self.state = state
        if let item = item, let qrCodedata = item.qrCodeData {
            self.qrCodeData = qrCodedata
        } else {
            let data = data?.data ?? [:]
            self.qrCodeData = QRCodeData(type: type, data: data, backgroundHexColor: "#FFFFFF", foregroundHexColor: "#000000")
        }
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if state == .preview || state == .editing {
            updateQRCode()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appeared = true
    }
    
    private func setupUI() {
        view.backgroundColor = R.color.cF1F1F1()
        navigationItem.title = qrCodeData.type.createTitle
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]
        switch state {
        case .preview:
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editCode))
        case .editing:
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", menu: createMenu())
        case .creating:
            break
        }
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancelEditing))
        view.addGestureRecognizer(tap)
    }
    
    @objc
    private func cancelEditing() {
        view.endEditing(true)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let section = Section(rawValue: sectionIndex)!
            
            switch section {
            case .preview:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(147))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(157))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 0)
                return section
            case .wifiType:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(52))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(52))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 8
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
                return section
            case .data:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(76))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(76))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 8
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
                return section
            case .colors:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(76))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(76))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 8
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
                return section
            }
        }
        return layout
    }
    
    private func updateCollectionViewLayout() {
        UIView.animate(withDuration: 0.3) {
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.layoutIfNeeded()
        }
    }
    
    @objc
    private func editCode() {
        HapticGenerator.shared.generateImpact()
        let vc = QRCodeCreatorViewController(type: qrCodeData.type, data: nil, item: item, state: .editing)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func createMenu() -> UIMenu {
        let saveChanges = UIAction(
            title: "Save Changes",
            image: UIImage(systemName: "doc"),
            handler: { [weak self] _ in
                guard let self, let item = self.item else { return }
                HapticGenerator.shared.generateImpact()
                qrCodeProcessor.saveChanges(item: item, modifiedData: qrCodeData)
                navigationController?.popToRootViewController(animated: true)
            }
        )
        let saveAsNew = UIAction(
            title: "Save As New",
            image: UIImage(systemName: "doc.on.doc"),
            handler: { [weak self] _ in
                guard let self, let item = self.item else { return }
                HapticGenerator.shared.generateImpact()
                qrCodeProcessor.saveAsCopy(item: item, modifiedData: qrCodeData)
                navigationController?.popToRootViewController(animated: true)
            }
        )
        return UIMenu(children: [saveChanges, saveAsNew])
    }
    
    private func updateQRCode(initial: Bool = false) {
        guard appeared || state == .preview || state == .editing else { return }
        let content = generateContent()
        let backgroundColor: UIColor = {
            if let hex = qrCodeData.backgroundHexColor {
                return UIColor.colorWithHexString(hexString: hex)
            }
            return selectedBackgroundColor ?? .white
        }()
        let foregroundColor: UIColor = {
            if let hex = qrCodeData.foregroundHexColor {
                return UIColor.colorWithHexString(hexString: hex)
            }
            return selectedForegroundColor ?? .black
        }()
        if let qrCodeData = QRGenerator.shared.generateQRCode(
            from: content,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        ),
           let image = UIImage(data: qrCodeData) {
            qrCodeImage = image
            if !initial {
                (collectionView.cellForItem(at: IndexPath(row: 0, section: Section.preview.rawValue)) as? QRCodePreviewCell)?.updateImage(image)
            }
        }
    }
    
    private func generateContent() -> String {
        switch qrCodeData.type {
        case .text:
            return qrCodeData.data["text"] ?? ""
        case .wifi:
            let ssid = qrCodeData.data["name"] ?? ""
            let password = qrCodeData.data["password"] ?? ""
            let type = qrCodeData.data["type"] ?? "WPA"
            return "WIFI:T:\(type);S:\(ssid);P:\(password);;"
        case .url:
            return qrCodeData.data["url"] ?? ""
        case .contact:
            let name = qrCodeData.data["name"] ?? ""
            let phone = qrCodeData.data["phone"] ?? ""
            let email = qrCodeData.data["email"] ?? ""
            let url = qrCodeData.data["url"] ?? ""
            return """
            BEGIN:VCARD
            VERSION:3.0
            N:\(name)
            TEL:\(phone)
            EMAIL:\(email)
            URL:\(url)
            END:VCARD
            """
        }
    }
}

extension QRCodeCreatorViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Section.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .preview:
            return 1
        case .wifiType:
            if qrCodeData.type != .wifi {
                return 0
            }
            return 1
        case .data:
            return qrCodeData.inputFields.count
        case .colors:
            if state == .preview {
                return 0
            }
            return 2
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Unknown section")
        }
        
        switch section {
        case .preview:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QRCodePreviewCell.reuseIdentifier, for: indexPath) as! QRCodePreviewCell
            cell.configure(
                with: qrCodeImage,
                download: { [weak self] in
                    self?.saveQRCodeToGallery()
                },
                share: { [weak self] in
                    self?.shareQRCode()
                }
            )
            return cell
        case .wifiType:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QRCodeWifiTypeCell.reuseIdentifier, for: indexPath) as! QRCodeWifiTypeCell
            cell.configure(
                selected: qrCodeData.data["Type"] ?? "WPA",
                onChanged: { [weak self] value in
                    let type: WifiType? = {
                        switch value {
                        case 0:
                            return .wpa
                        case 1:
                            return .wep
                        case 2:
                            return .free
                        default:
                            return nil
                        }
                    }()
                    guard let type else { return }
                    self?.updateQRCodeData(key: "Type", value: type.rawValue)
                })
            cell.isUserInteractionEnabled = state == .editing || state == .creating
            return cell
        case .data:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InputFieldCell.reuseIdentifier, for: indexPath) as! InputFieldCell
            let fields = qrCodeData.inputFields
            let field = fields[indexPath.item]
            cell.configure(with: field)
            cell.onValueChanged = { [weak self] newValue in
                self?.updateQRCodeData(key: field.key, value: newValue)
            }
            cell.onBeginEditing = { [weak self] in
                self?.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
            cell.isUserInteractionEnabled = state == .editing || state == .creating
            return cell
        case .colors:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorPickerCell.reuseIdentifier, for: indexPath) as! ColorPickerCell
            
            let backgroundColor: UIColor = {
                if let hex = qrCodeData.backgroundHexColor {
                    return UIColor.colorWithHexString(hexString: hex)
                }
                return selectedBackgroundColor ?? .white
            }()
            let foregroundColor: UIColor = {
                if let hex = qrCodeData.foregroundHexColor {
                    return UIColor.colorWithHexString(hexString: hex)
                }
                return selectedForegroundColor ?? .black
            }()

            cell.configure(
                title: indexPath.item == 0 ? "Background color" : "Body color",
                selectedColor: indexPath.item == 0 ? backgroundColor : foregroundColor,
                onColorSelected: { [weak self] color in
                    if indexPath.item == 0 {
                        self?.qrCodeData.backgroundHexColor = color.hexStringFromColor()
                    } else {
                        self?.qrCodeData.foregroundHexColor = color.hexStringFromColor()
                    }
                    self?.updateQRCode()
                }
            )
            cell.isUserInteractionEnabled = state == .editing || state == .creating
            return cell
        }
    }
    
    private func updateQRCodeData(key: String, value: String) {
        qrCodeData.data[key] = value
        updateQRCode()
        updateCollectionViewLayout()
    }
    
    private func saveQRCodeToGallery() {
        guard let qrImage = qrCodeImage else { return }
        saveToGallery(qrImage: qrImage) { saved, error in
            onMain {
                if saved {
                    // ToastViewController.showToast(with: "Saved to Gallery!", with: "checkmark")
                } else if error != nil {
                    // ToastViewController.showToast(with: error?.localizedDescription ?? "Failed to save", with: "exclamationmark.circle")
                }
            }
        }
        qrCodeProcessor.save(qrCodeData: qrCodeData)
    }
    
    private func shareQRCode() {
        guard let qrImage = qrCodeImage else { return }
        share(qrImage: qrImage, onViewController: self)
        qrCodeProcessor.save(qrCodeData: qrCodeData)
    }
}
