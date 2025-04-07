import UIKit
import SnapKit
import RxSwift

final class QRCodePreviewView: UIView {
    private let qrImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15.0
        imageView.startAnimating()
        imageView.image = R.image.qrCodePlacholder()
        return imageView
    }()
    
    private lazy var downloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Download", for: .normal)
        button.setImage(R.image.qrDownload.callAsFunction(), for: .normal)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true

        
        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = .white
        config.baseBackgroundColor = R.color.accentColor()
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ container in
            var container = container
            container.font = R.font.interMedium(size: 14)
            return container
        })
        button.configuration = config
        button.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)

        return button
    }()
    
    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share", for: .normal)
        button.setImage(R.image.qrShare.callAsFunction(), for: .normal)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true

        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = R.color.accentColor()
        config.baseBackgroundColor = R.color.c000000o8()
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ container in
            var container = container
            container.font = R.font.interMedium(size: 14)
            return container
        })
        button.configuration = config
        button.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

        return button
    }()
    
    var download: (() -> Void)?
    var share: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = R.color.cF1F1F1()
        
        addSubview(qrImageView)
        addSubview(downloadButton)
        addSubview(shareButton)
        qrImageView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(147)
        }
        
        downloadButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.trailingMargin.equalToSuperview().offset(-16)
            make.height.equalTo(44)
            make.width.equalTo(187)
        }
        
        shareButton.snp.makeConstraints { make in
            make.top.equalTo(downloadButton.snp.bottom).offset(8)
            make.trailingMargin.equalToSuperview().offset(-16)
            make.height.equalTo(44)
            make.width.equalTo(187)
        }
    }
    
    func setQRImage(_ image: UIImage) {
        qrImageView.image = image
    }
    
    @objc
    private func downloadTapped() {
        HapticGenerator.shared.generateImpact()
        download?()
    }
    
    @objc
    private func shareTapped() {
        HapticGenerator.shared.generateImpact()
        share?()
    }
    
    func getQRCodeImage() -> UIImage? {
        return qrImageView.image
    }
}

final class QRCodePreviewCell: UICollectionViewCell {
    static let reuseIdentifier = "QRCodePreviewCell"
    
    private let qrCodePreview: QRCodePreviewView = {
        let view = QRCodePreviewView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 15
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(qrCodePreview)
        qrCodePreview.snp.makeConstraints { make in
            make.height.equalTo(147)
            make.edges.equalToSuperview()
        }

    }
    
    func configure(with image: UIImage?, download: @escaping (() -> Void), share: @escaping (() -> Void)) {
        qrCodePreview.download = {
            download()
        }
        qrCodePreview.share = {
            share()
        }
        guard let image else { return }
        qrCodePreview.setQRImage(image)
    }
    
    func updateImage(_ image: UIImage) {
        qrCodePreview.setQRImage(image)
    }
}


final class QRCodeWifiTypeCell: UICollectionViewCell {
    static let reuseIdentifier = "QRCodeWifiTypeCell"
    
    private lazy var wifiTypeSegment: UISegmentedControl = {
        let items: [String] = {
            return WifiType.allCases.compactMap { item in
                return item.rawValue
            }
        }()
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        return control
    }()
    private let disposeBag: DisposeBag = DisposeBag()
    private var onChanged: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(wifiTypeSegment)
        wifiTypeSegment.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        wifiTypeSegment.rx
            .selectedSegmentIndex
            .subscribe(onNext: { [weak self] value in
                self?.onChanged?(value)
            })
            .disposed(by: disposeBag)
    }
    
    func configure(selected: String, onChanged: @escaping ((Int) -> Void)) {
        self.onChanged = onChanged
        
        if let index = WifiType.allCases.firstIndex(where: { $0.rawValue == selected }) {
            wifiTypeSegment.selectedSegmentIndex = index
        }
    }
}
