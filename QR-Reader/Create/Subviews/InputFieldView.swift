import UIKit
import SnapKit
import RxCocoa
import RxSwift

struct Field {
    enum FieldType {
        case text
        case networkName
        case networkPassword
        case url
//        case email
//        case emailSubject
//        case emailBody
        case contactName
        case contactNumber
        case contactMail
        case contactURL
        
        var configURLKeyboard: Bool {
            switch self {
            case .contactURL, .url:
                return true
            default:
                return false
            }
        }
    }
    let fieldType: FieldType
    let title: String
    let placeholder: String
    let value: String?
}

final class InputFieldView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .gray
        return label
    }()
    
    lazy var textField: UITextField = {
        let field = UITextField()
        field.font = UIFont.systemFont(ofSize: 16)
        return field
    }()
    var text: String {
        textField.text ?? ""
    }
    
    init(field: Field) {
        super.init(frame: .zero)
        setupView()
        configure(title: field.title, placeholder: field.placeholder)
        if field.fieldType.configURLKeyboard {
            textField.keyboardType = .URL
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        
        addSubview(titleLabel)
        addSubview(textField)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(8)
        }
    }
    
    func configure(title: String, placeholder: String) {
        titleLabel.text = title
        textField.placeholder = placeholder
    }
    
    func setText(_ value: String?) {
        textField.text = value
    }
}

