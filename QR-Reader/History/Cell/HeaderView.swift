import UIKit
import SnapKit

final class CustomHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "CustomHeaderView"
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = R.font.interSemiBold(size: 18)
        label.textColor = .black
        return label
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
    }
}
