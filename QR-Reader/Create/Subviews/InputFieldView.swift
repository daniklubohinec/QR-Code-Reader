import UIKit
import SnapKit
import RxCocoa
import RxSwift
import PhoneNumberKit

struct Field {
    enum FieldType {
        case text
        case networkName
        case networkPassword
        case url
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
    
    var key: String {
        switch fieldType {
        case .text:
            return "Text"
        case .networkName:
            return "WiFi Name"
        case .networkPassword:
            return "Password"
        case .url:
            return "URL"
        case .contactName:
            return "Contact Name"
        case .contactNumber:
            return "Phone Number"
        case .contactMail:
            return "Mail"
        case .contactURL:
            return "URL"
        }
    }
}

final class InputFieldCell: UICollectionViewCell {
    static let reuseIdentifier = "InputFieldCell"
    private var field: Field?
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = R.font.interMedium(size: 13)
        label.textColor = R.color.c030303()?.withAlphaComponent(0.5)
        return label
    }()
    private lazy var phoneField: PhoneNumberTextField = {
        let field = PhoneNumberTextField(withPhoneNumberKit: PhoneNumberKit())
        field.withExamplePlaceholder = true
        field.isPartialFormatterEnabled = true
        field.font = R.font.interMedium(size: 14)
        field.textColor = R.color.c030303()
        field.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        field.delegate = self
        return field
    }()
    lazy var textView: UITextView = {
        let text = UITextView()
        text.isScrollEnabled = false
        text.font = R.font.interMedium(size: 14)
        text.textColor = R.color.c030303()
        text.text = ""
        return text
    }()
    private lazy var _textField: UITextField = {
        let field = UITextField()
        field.font = R.font.interMedium(size: 14)
        field.textColor = R.color.c030303()
        field.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        field.autocorrectionType = .no
        field.delegate = self
        return field
    }()
    private var textViewHeightConstraint: Constraint?
    private let disposeBag = DisposeBag()
    private var throttleTimer: Timer?
    private var lastInvocationTime: TimeInterval = 0

    var textViewShowed: Bool {
        textView.superview != nil
    }
    var textField: UITextField? {
        switch field?.fieldType {
        case .text:
            return nil
        case .contactNumber:
            return phoneField
        default:
            return _textField
        }
    }
    var text: String {
        switch field?.fieldType {
        case .text:
            return textView.text
        case .contactNumber:
            return phoneField.text ?? ""
        default:
            return _textField.text ?? ""
        }
    }
    var onValueChanged: ((String) -> Void)?
    var onBeginEditing: (() -> Void)?

    override init(frame: CGRect) {
        self.field = nil
        super.init(frame: frame)
        setupView()
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
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(18)
        }
        setupTextView()
        setupPhoneField()
        setupTextField()
    }
    
    func configure(with field: Field) {
        self.field = field
        titleLabel.text = field.title
        _textField.placeholder = field.placeholder
        
        switch field.fieldType {
        case .text:
            textView.isHidden = false
            _textField.isHidden = true
            phoneField.isHidden = true
            updateTextViewHeight()
        case .contactNumber:
            textView.isHidden = true
            _textField.isHidden = true
            phoneField.isHidden = false
        default:
            textView.isHidden = true
            _textField.isHidden = false
            phoneField.isHidden = true
        }
        
        if field.fieldType.configURLKeyboard {
            _textField.keyboardType = .URL
        }
        setText(field.value)
    }
    
    private func setupTextView() {
        guard !textViewShowed else { return }
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
            textViewHeightConstraint = make.height.equalTo(20).priority(.high).constraint
        }
        textView.delegate = self
    }
    
    private func setupPhoneField() {
        guard phoneField.superview == nil else { return }
        addSubview(phoneField)
        phoneField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(8)
        }
    }
    
    private func setupTextField() {
        guard _textField.superview == nil else { return }
        addSubview(_textField)
        _textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(8)
        }
    }
    
    func setText(_ value: String?) {
        switch field?.fieldType {
        case .text:
            textView.text = value
        case .contactNumber:
            phoneField.text = value
        default:
            _textField.text = value
        }
    }
    
    func updateTextViewHeight() {
        guard !textView.isHidden else { return }
        let size = CGSize(width: textView.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)
        let newHeight = min(max(20, estimatedSize.height), 200)
        
        textViewHeightConstraint?.update(offset: newHeight)
        
        textView.isScrollEnabled = newHeight >= 200
        
        layoutIfNeeded()
    }
    
    @objc private func textFieldChanged() {
        guard let fieldType = field?.fieldType else { return }
        var newValue: String?
        switch fieldType {
        case .text:
            newValue = textView.text
        case .contactNumber:
            newValue = phoneField.text
        default:
            newValue = textField?.text
        }
        guard let newValue else { return }
        throttleUpdate(newValue)
    }
    
    private func throttleUpdate(_ newValue: String) {
        throttleTimer?.invalidate()
        throttleTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.lastInvocationTime = Date().timeIntervalSince1970
            self?.onValueChanged?(newValue)
        }
    }
}

extension InputFieldCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateTextViewHeight()
        onValueChanged?(textView.text)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        onBeginEditing?()
    }
}

extension InputFieldCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        onBeginEditing?()
    }
}
