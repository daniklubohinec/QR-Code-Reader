import UIKit
import SnapKit
import NetworkExtension
import Contacts
import ContactsUI

enum QRCodeResultType: Codable, Equatable {
    case barcode, text, url, email, message, contact, wifi, location, unknown
    
    var defaultDisplayOrder: [String] {
        switch self {
        case .url:
            return ["URL"]
        case .email:
            return ["Mail", "Subject", "Message"]
        case .message:
            return ["Phone Number", "Message"]
        case .contact:
            return ["Contact Name", "Phone Number", "Mail", "URL"]
        case .wifi:
            return ["WiFi Name", "Password", "Type"]
        case .location:
            return ["Location"]
        case .barcode, .text, .unknown:
            return ["Text"]
        }
    }
    
    var qrCodeType: QRCodeData.QRCodeType? {
        switch self {
        case .text:
            return .text
        case .url:
            return .url
        case .contact:
            return .contact
        case .wifi:
            return .wifi
        default: return nil
        }
    }
    
    var name: String {
        switch self {
        case .barcode:
            return "Barcode"
        case .text:
            return "Text"
        case .url:
            return "URL"
        case .email:
            return "Email"
        case .message:
            return "Message"
        case .contact:
            return "Contact"
        case .wifi:
            return "WiFi"
        case .location:
            return "Location"
        case .unknown:
            return "Unknown"
        }
    }
}

struct QRCodeScanResult: Codable, Equatable {
    enum ViewMode: Codable {
        case view
        case scan
    }
    let type: QRCodeResultType
    let viewMode: ViewMode
    let data: [String: String]
    let rawCode: String
    let displayOrder: [String]
    
    var name: String {
        switch type {
        case .barcode, .text:
            return data["Text"] ?? rawCode
        case .url:
            return data["URL"] ?? rawCode
        case .email:
            return data["Mail"] ?? rawCode
        case .message:
            return data["Message"] ?? rawCode
        case .contact:
            return data["Contact Name"] ?? rawCode
        case .wifi:
            return rawCode
        case .location:
            return rawCode
        case .unknown:
            return rawCode
        }
    }
    
    func withUpdatedViewMode(_ value: ViewMode) -> Self {
        return Self(type: type, viewMode: value, data: data, rawCode: rawCode, displayOrder: displayOrder)
    }
}

final class QRCodeResultViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case image, data
    }
    
    private let scanResult: QRCodeScanResult
    private let qrCodeImage: UIImage
    private lazy var qrProcessor: QRDataProcessor = {
        return QRDataProcessor()
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = R.color.cF1F1F1()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(QRCodeImageCell.self, forCellWithReuseIdentifier: QRCodeImageCell.reuseIdentifier)
        collectionView.register(QRCodeDataCell.self, forCellWithReuseIdentifier: QRCodeDataCell.reuseIdentifier)
        return collectionView
    }()
    private lazy var overlayView: UIView = {
        return UIView()
    }()
    private lazy var actionContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = R.color.cF1F1F1()
        overlayView.backgroundColor = R.color.cF1F1F1()
        view.addSubview(overlayView)

        let downloadButton = UIButton(type: .system)
        downloadButton.clipsToBounds = true
        downloadButton.layer.cornerRadius = 15
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = R.color.accentColor()?.withAlphaComponent(0.1)
        configuration.baseForegroundColor = R.color.accentColor()
        configuration.imagePadding = 8
        configuration.image = UIImage(named: "QrDownload")
        configuration.title = "Download as Image"
        downloadButton.configuration = configuration
        downloadButton.addTarget(self, action: #selector(download), for: .touchUpInside)
        
        let shareButton = UIButton(type: .system)
        shareButton.clipsToBounds = true
        shareButton.layer.cornerRadius = 15
        var shareConfiguration = UIButton.Configuration.filled()
        shareConfiguration.baseBackgroundColor = R.color.accentColor()
        shareConfiguration.baseForegroundColor = .white
        shareConfiguration.title = {
            switch scanResult.type {
            case .email:
                return "Open in Mail"
            case .message:
                return "Open in Messages"
            case .url:
                return "Open in Safari"
            case .contact:
                return "Add to Contacts"
            case .wifi:
                return "Connect WiFi"
            case .location:
                return "Open in Maps"
            case .barcode, .text:
                return "Open in Safari"
            case .unknown:
                return "Unknown metadata"
            }
        }()
        shareButton.configuration = shareConfiguration
        shareButton.addTarget(self, action: #selector(openIn), for: .touchUpInside)
        
        view.addSubview(downloadButton)
        view.addSubview(shareButton)
        downloadButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(60)
        }
        shareButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(downloadButton.snp.bottom).offset(8)
            make.height.equalTo(60)
        }
        // Настраиваем constraints для overlayView
        overlayView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(downloadButton.snp.top)
        }
        view.clipsToBounds = true
        
        return view
    }()
    private var prevTintColor: UIColor?

    init(scanResult: QRCodeScanResult, image: UIImage) {
        self.scanResult = scanResult
        self.qrCodeImage = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        overlayView.applyGradientMask()
    }
    
    override func viewDidLoad() {

        prevTintColor = navigationController?.navigationBar.tintColor
        navigationItem.largeTitleDisplayMode = .never
        
        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]

        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = R.color.cF1F1F1()
        navigationItem.title = scanResult.type == .barcode ? "EAN-13" : "QR Code"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
        
        view.addSubview(collectionView)
        view.addSubview(actionContainerView)
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 218, right: 0)
        actionContainerView.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(218)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if scanResult.viewMode == .scan {
            qrProcessor.saveScanResult(result: scanResult)
        }
    }
    
    @objc 
    private func shareTapped() {
        share(qrImage: qrCodeImage, onViewController: self)
    }
    
    @objc 
    private func download() {
        saveToGallery(qrImage: qrCodeImage)
    }
    
    @objc
    private func openIn() {
        var openingUrl: URL?
        switch scanResult.type {
        case .barcode, .text:
            let formattedText = scanResult.data["Text"]?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "mobilenotes://x-callback-url/create?text=\(formattedText)"), !formattedText.isEmpty {
                openingUrl = url
            }
        case .url:
            guard let url = scanResult.data["URL"], let url = URL(string: url) else { return }
            openingUrl = url
        case .email:
            guard let sender = scanResult.data["Mail"], let subject = scanResult.data["Subject"], let body = scanResult.data["Message"] else { return }
            let urlString = "mailto:\(sender)?subject=\(subject)&body=\(body)"
            if let url = URL(string: urlString) {
                openingUrl = url
            }
        case .message:
            guard let sender = scanResult.data["Phone Number"], let message = scanResult.data["Message"] else { return }
            let urlString = "sms:\(sender)&body=\(message)"
            if let url = URL(string: urlString) {
                openingUrl = url
            }
        case .contact:
            addToContact()
            return
        case .wifi:
            guard let ssid = scanResult.data["WiFi Name"], let pass = scanResult.data["Password"] else { return }
            connectToWiFi(ssid: ssid, passphrase: pass)
        case .location:
            guard let location = scanResult.data["Location"] else { return }
            let urlString = "maps://?ll=\(location)"
            if let url = URL(string: urlString) {
                openingUrl = url
            }
        case .unknown:
            return
        }
        if let openingUrl {
            if UIApplication.shared.canOpenURL(openingUrl) {
                UIApplication.shared.open(openingUrl, options: [:], completionHandler: nil)
            }
        }
    }
    
    func connectToWiFi(ssid: String, passphrase: String) {
        let hotspotConfig = NEHotspotConfiguration(ssid: ssid, passphrase: passphrase, isWEP: false)
        NEHotspotConfigurationManager.shared.apply(hotspotConfig) { error in
            print(error?.localizedDescription)
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let section = Section(rawValue: sectionIndex)!
            
            switch section {
            case .image:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(147))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(147))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
                return section
                
            case .data:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(60))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(60))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 8
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
                return section
            }
        }
        return layout
    }

    func addToContact() {
        guard let contact = scanResult.cnContact else { return }
        let vc = CNContactViewController(forNewContact: contact)
        present(vc, animated: true)
    }
}

extension QRCodeScanResult {
    var cnContact: CNContact? {
        guard let phone = data["Phone Number"], let name = data["Contact Name"] else { return  nil }

        let contact = CNMutableContact()
        contact.givenName = name
        contact.phoneNumbers = [.init(label: nil, value: .init(stringValue: phone))]
        if let url = data["URL"]  {
            contact.urlAddresses = [.init(label: nil, value: url as NSString)]
        }
        if let mail = data["Mail"] {
            contact.emailAddresses = [.init(label: nil, value: mail as NSString)]
        }
        
        return contact
    }
}

extension QRCodeResultViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Section.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .image:
            return 1
        case .data:
            return scanResult.data.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Unknown section")
        }
        
        switch section {
        case .image:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QRCodeImageCell.reuseIdentifier, for: indexPath) as! QRCodeImageCell
            cell.configure(with: qrCodeImage, type: scanResult.type)
            return cell
        case .data:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QRCodeDataCell.reuseIdentifier, for: indexPath) as! QRCodeDataCell
            let key = scanResult.displayOrder[indexPath.item]
            let value = scanResult.data[key] ?? ""
            cell.configure(key: key, value: value)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
    
    private func performAction() {
        // Реализация действия в зависимости от типа результата
    }
}

final class QRCodeImageCell: UICollectionViewCell {
    static let reuseIdentifier = "QRCodeImageCell"
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
    }
    
    func configure(with image: UIImage, type: QRCodeResultType) {
        imageView.image = image
        imageView.snp.makeConstraints { make in
            make.height.equalTo(147)
            make.width.equalTo(type == .barcode ? 216 : 147)
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }
}

final class QRCodeDataCell: UICollectionViewCell {
    static let reuseIdentifier = "QRCodeDataCell"
    
    private let keyLabel: UILabel = {
        let label = UILabel()
        label.font = R.font.interMedium(size: 13)
        label.textColor = R.color.c030303()?.withAlphaComponent(0.5)
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = R.font.interMedium(size: 14)
        label.textColor = R.color.c030303()
        label.numberOfLines = 0
        return label
    }()
    
    private let copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "Duplicate"), for: .normal)
        button.tintColor = R.color.c030303()
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 15
        
        contentView.addSubview(keyLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(copyButton)
        
        keyLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(keyLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(copyButton.snp.leading).offset(-16)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        copyButton.snp.makeConstraints { make in
            make.centerY.equalTo(keyLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(CGSize(width: 18, height: 18))
        }
        
        copyButton.addTarget(self, action: #selector(copyValue), for: .touchUpInside)
    }
    
    func configure(key: String, value: String) {
        keyLabel.text = key
        valueLabel.text = value
    }
    
    @objc private func copyValue() {
        UIPasteboard.general.string = valueLabel.text
        ToastViewController.showToast(with: "Copied", with: "Duplicate")
    }
}
