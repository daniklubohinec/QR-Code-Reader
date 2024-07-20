import UIKit
import SnapKit

final class HistoryItemTableViewCell: UITableViewCell {
    static let reuseIdentifier: String = "HistoryItemTableViewCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.clipsToBounds = true
        view.layer.cornerRadius = 15
        return view
    }()
    private let qrImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = R.font.interSemiBold(size: 14)
        label.textColor = R.color.c030303()
        return label
    }()
    
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.font = R.font.interMedium(size: 13)
        label.textColor = R.color.c030303()?.withAlphaComponent(0.3)
        return label
    }()
    private let separatorLabel: UILabel = {
        let label = UILabel()
        label.font = R.font.interMedium(size: 13)
        label.textColor = R.color.c030303()?.withAlphaComponent(0.3)
        label.text = "•"
        return label
    }()
    private let typeNameLabel: UILabel = {
        let label = UILabel()
        label.font = R.font.interMedium(size: 13)
        label.textColor = R.color.c030303()?.withAlphaComponent(0.3)
        return label
    }()
    private let disclosureIndicatorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = R.color.c030303()?.withAlphaComponent(0.3)
        return imageView
    }()
    private let spacer = UIView()
    var item: HistoryItem?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        spacer.backgroundColor = .clear
        selectionStyle = .none
        containerView.addSubview(qrImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(typeLabel)
        containerView.addSubview(separatorLabel)
        containerView.addSubview(typeNameLabel)
        containerView.addSubview(disclosureIndicatorImageView)
        
        contentView.addSubview(containerView)
        contentView.addSubview(spacer)
        
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        spacer.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(8.0)
        }
        containerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview()
            make.bottom.equalTo(spacer.snp.top)
        }
        qrImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(50)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(qrImageView.snp.trailing).offset(16)
            make.trailing.equalTo(disclosureIndicatorImageView.snp.leading).offset(-8)
            make.top.equalToSuperview().offset(14)
        }
        
        typeLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
        }
        separatorLabel.snp.makeConstraints { make in
            make.leading.equalTo(typeLabel.snp.trailing).offset(8)
            make.centerY.equalTo(typeLabel)
        }
        
        typeNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(separatorLabel.snp.trailing).offset(8)
            make.centerY.equalTo(typeLabel)
        }
        disclosureIndicatorImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(25)
        }
    }
    
    func configure(with item: HistoryItem) {
        self.item = item
        nameLabel.text = item.name
        typeLabel.text = "QR"
        typeNameLabel.text = item.typeName
        
        if let image = UIImage(data: item.qrCodeImageData) {
            qrImageView.image = image
        } else {
            qrImageView.image = UIImage(systemName: "qrcode")
        }
    }
}
