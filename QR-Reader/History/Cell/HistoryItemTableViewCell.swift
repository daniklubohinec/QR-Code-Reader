import UIKit
import SnapKit
import RxSwift

enum SwipeAction {
    case delete
    case more
    
    var backgroundColor: UIColor {
        switch self {
        case .delete: return UIColor.colorWithHexString(hexString: "#FE4848")
        case .more: return UIColor.colorWithHexString(hexString: "#AEAEB2")
        }
    }
    
    var image: UIImage? {
        switch self {
        case .delete: return UIImage(systemName: "trash.fill")
        case .more: return UIImage(systemName: "ellipsis.circle.fill")
        }
    }
}

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
    private let contentContainer = UIView()
    private let actionsStackView = UIStackView()
    
    private var actions: [SwipeAction] = []
    private let actionButtonWidth: CGFloat = 70
    private var leadingConstraint: Constraint?
    var onSwipeAction: ((SwipeAction) -> Void)?

    private let spacer = UIView()
    private let disposeBag = DisposeBag()
    var item: HistoryItem?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupSwipeGesture()
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
        
        contentView.addSubview(actionsStackView)
        contentView.addSubview(contentContainer)
        contentView.sendSubviewToBack(actionsStackView)

        contentContainer.addSubview(containerView)
        
        actionsStackView.axis = .horizontal
        actionsStackView.distribution = .fillEqually
        actionsStackView.alignment = .fill
        actionsStackView.layer.cornerRadius = 15
        actionsStackView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        actionsStackView.clipsToBounds = true

        actionsStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(spacer.snp.top)
            make.width.equalTo(actionButtonWidth * 2)
        }
        
        contentContainer.snp.makeConstraints { make in
            make.top.bottom.width.equalToSuperview()
            leadingConstraint = make.leading.equalToSuperview().constraint
        }
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
    
    private func setupSwipeGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        contentContainer.addGestureRecognizer(panGesture)
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
        configureSwipeActions([.more, .delete])
    }
    
    
    private func configureSwipeActions(_ actions: [SwipeAction]) {
        self.actions = actions
        setupActionButtons()
    }
    
    private func setupActionButtons() {
        actionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for action in actions {
            let button = UIButton()
            button.backgroundColor = action.backgroundColor
            button.setImage(action.image, for: .normal)
            button.tintColor = .white
            button.rx.tap
                .asDriver()
                .drive(onNext: { [weak self] in
                    self?.onSwipeAction?(action)
                })
                .disposed(by: disposeBag)
            actionsStackView.addArrangedSubview(button)
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: contentContainer)
        let totalActionWidth = CGFloat(actions.count) * actionButtonWidth
        
        switch gesture.state {
        case .began, .changed:
            if translation.x < 0 {
                leadingConstraint?.update(offset: max(-totalActionWidth, translation.x))
            } else if contentContainer.frame.minX < 0 {
                leadingConstraint?.update(offset: min(0, translation.x - totalActionWidth))
            }
            
        case .ended:
            if translation.x < -actionButtonWidth {
                showActions()
            } else {
                hideActions()
            }
            
        default:
            break
        }
        
        UIView.animate(withDuration: 0.1) {
            self.layoutIfNeeded()
        }
    }
    
    private func showActions() {
        leadingConstraint?.update(offset: -CGFloat(actions.count) * actionButtonWidth)
        animateLayoutChanges()
    }
    
    func hideActions() {
        leadingConstraint?.update(offset: 0)
        animateLayoutChanges()
    }
    
    private func animateLayoutChanges() {
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
}
extension UIView {
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
