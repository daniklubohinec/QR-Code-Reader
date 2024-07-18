import UIKit
import CoreImage
import CoreTelephony
import Photos
import RxSwift
import RxCocoa

enum QRCodeType: Codable, Hashable, Equatable {
    case text(TextQRModel?)
    case wifi(WifiQRModel?)
    case url(URLQRModel?)
    case contact(ContactQRModel?)
    
    var name: String {
        switch self {
        case .text:
            return "Text"
        case .wifi:
            return "WiFi"
        case .url:
            return "URL"
        case .contact:
            return "Contact"
        }
    }
    
    var title: String {
        switch self {
        case .text: return "Create Text"
        case .wifi: return "Create WiFi"
        case .url: return "Create URL"
        case .contact: return "Create Contact"
        }
    }
    var isWifi: Bool {
        switch self {
        case .wifi:
            return true
        default:
            return false
        }
    }
    var wifiType: WifiQRModel.WifiType? {
        switch self {
        case .wifi(let model):
            return model?.type
        default:
            return nil
        }
    }
    
    var inputFields: [Field] {
        switch self {
        case .text(let model): 
            return [
                Field(
                    fieldType: .text,
                    title: "Text",
                    placeholder: "Enter text",
                    value: model?.text
                )
            ]
        case .wifi(let model): return [
            Field(
                fieldType: .networkName,
                title: "WiFi Name",
                placeholder: "Enter network name",
                value: model?.name
            ),
            Field(
                fieldType: .networkPassword,
                title: "Password",
                placeholder: "Enter password",
                value: model?.password
            )
        ]
        case .url(let model):
            return [
                Field(
                    fieldType: .url,
                    title: "URL",
                    placeholder: "Enter link",
                    value: model?.url
                )
            ]
        case .contact(let model):
            return [
                Field(
                    fieldType: .contactName,
                    title: "Contact Name",
                    placeholder: "Enter contact name",
                    value: model?.name
                ),
                Field(
                    fieldType: .contactNumber,
                    title: "Phone Number",
                    placeholder: "Enter phone number",
                    value: model?.phone
                ),
                Field(
                    fieldType: .contactMail,
                    title: "Mail",
                    placeholder: "Enter contact mail",
                    value: model?.mail
                ),
                Field(
                    fieldType: .contactURL,
                    title: "URL",
                    placeholder: "Enter contact URL",
                    value: model?.url
                )
            ]
        }
    }
    
    static func ==(lhs: QRCodeType, rhs: QRCodeType) -> Bool {
        switch lhs {
        case .wifi(let lhsValue):
            if case .wifi(let rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
        case .url(let lhsValue):
            if case .url(let rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
        case .text(let lhsValue):
            if case .text(let rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false

        case .contact(let lhsValue):
            if case .contact(let rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
        }
    }
}

final class QRCodeCreatorViewController: UIViewController {
    struct InputItem {
        let field: Field.FieldType
        let input: InputFieldView
    }
    private let qrCodeType: QRCodeType
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private lazy var qrCodePreview: QRCodePreviewView = {
        let view = QRCodePreviewView()
        view.download = { [weak self] in
            guard let self else { return }
            if self.item == nil {
                qrDataProcessor.save()
            }

            saveQRCodeToGallery(completion: { saved, error in
                guard saved else {
                    ToastViewController.showToast(with: error?.localizedDescription ?? "", with: "exclamationmark.circle")
                    return
                }
                ToastViewController.showToast(with: "Saved to Gallery!", with: "checkmark")
            })
        }
        view.share = { [weak self] in
            guard let self else { return }
            
            if self.item == nil {
                qrDataProcessor.save()
            }
            shareQRCode()
        }
        return view
    }()
    private lazy var wifiTypeSegment: UISegmentedControl = {
        let items: [String] = {
            return WifiQRModel.WifiType.allCases.compactMap { item in
                if item == .free {
                    return "FREE"
                }
                return item.rawValue
            }
        }()
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        return control
    }()
    private var inputTextFields: [InputItem] = []
    private lazy var colorPickerBackground: ColorPickerView = {
        let view = ColorPickerView(title: "Background color")
        view.setOnColorSelected(completion: { [weak self] selectedColor in
            self?.selectedBackgroundColor = selectedColor
            self?.qrDataProcessor.backgroundColor = selectedColor
            self?.updateQRCode()
        })
        return view
    }()
    private lazy var colorPickerForeground: ColorPickerView = {
        let view = ColorPickerView(title: "Body color")
        view.setOnColorSelected(completion: { [weak self] selectedColor in
            self?.selectedForegroundColor = selectedColor
            self?.qrDataProcessor.foregroundColor = selectedColor
            self?.updateQRCode()
        })
        return view
    }()
    private var selectedBackgroundColor: UIColor?
    private var selectedForegroundColor: UIColor?
    
    private var keyboardHeight: CGFloat = 0
    private let item: HistoryItem?
    private let editingItem: Bool
    private lazy var qrDataProcessor: QRDataProcessor = {
        return QRDataProcessor(from: item?.qrCodeType ?? qrCodeType)
    }()
    
    init(type: QRCodeType, item: HistoryItem?, editingItem: Bool = false) {
        self.qrCodeType = type
        self.item = item
        self.editingItem = editingItem
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        setupKeyboardObservers()
        configureWithItem()
        bindModel()
        if item == nil {
            updateQRCode()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = R.color.cF1F1F1()
        title = qrCodeType.title
        if item != nil, !editingItem {
            title = qrCodeType.name
        } else if item != nil, editingItem {
            title = "Edit"
        }
        navigationItem.largeTitleDisplayMode = .never
        
        // Добавляем scrollView в иерархию view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(qrCodePreview)
        if (item?.qrCodeType.isWifi ?? false) || qrCodeType.isWifi {
            contentView.addSubview(wifiTypeSegment)
        }
        if item == nil || editingItem {
            contentView.addSubview(colorPickerBackground)
            contentView.addSubview(colorPickerForeground)
        }
        
        // Создаем текстовые поля
        for field in qrCodeType.inputFields {
            let textField = InputFieldView(field: field)
            textField.isUserInteractionEnabled = item == nil || editingItem
            
            inputTextFields.append(InputItem(field: field.fieldType, input: textField))
            contentView.addSubview(textField)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        contentView.addGestureRecognizer(tap)
        
        if item != nil {
            if editingItem {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", menu: createMenu())
            } else {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editCode))
            }
        }
        wifiTypeSegment.isUserInteractionEnabled = item == nil || editingItem
    }
    
    @objc
    private func editCode() {
        let vc = QRCodeCreatorViewController(type: qrCodeType, item: item, editingItem: true)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func createMenu() -> UIMenu {
        let saveChanges = UIAction(
            title: "Save Changes",
            image: UIImage(systemName: "doc"),
            handler: { [weak self] _ in
                guard let self, let item = self.item else { return }
                qrDataProcessor.saveChanges(item: item)
                navigationController?.popToRootViewController(animated: true)
            }
        )
        let saveAsNew = UIAction(
            title: "Save As New",
            image: UIImage(systemName: "doc.on.doc"),
            handler: { [weak self] _ in
                guard let self, let item = self.item else { return }
                qrDataProcessor.saveAsCopy(item: item)
                navigationController?.popToRootViewController(animated: true)
            }
        )
        return UIMenu(children: [saveChanges, saveAsNew])
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }
        
        qrCodePreview.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(16)
            make.leadingMargin.equalToSuperview().offset(16)
            make.trailingMargin.equalToSuperview().offset(-16)
            make.height.equalTo(147)
        }
        var lastView: UIView = qrCodePreview

        if wifiTypeSegment.superview != nil {
            wifiTypeSegment.snp.makeConstraints { make in
                make.top.equalTo(lastView.snp.bottom).offset(20)
                make.leading.equalTo(contentView).offset(16)
                make.trailing.equalTo(contentView).offset(-16)
            }
            lastView = wifiTypeSegment
        }
        
        
        for (index, item) in inputTextFields.enumerated() {
            let textField = item.input
            contentView.addSubview(textField)
            var topOffset = lastView is InputFieldView ? 8 : 20
            if lastView === wifiTypeSegment {
                topOffset = 15
            }
            
            textField.snp.makeConstraints { make in
                make.top.equalTo(lastView.snp.bottom).offset(topOffset)
                make.leading.equalTo(contentView).offset(16)
                make.trailing.equalTo(contentView).offset(-16)
                
                if case .text = qrCodeType, index == 0 {
                    make.height.lessThanOrEqualTo(200)
                } else {
                    make.height.equalTo(76)
                }
            }
            
            lastView = textField
        }
        if colorPickerBackground.superview != nil {
            colorPickerBackground.snp.makeConstraints { make in
                make.top.equalTo(lastView.snp.bottom).offset(20)
                make.leading.equalTo(contentView).offset(16)
                make.trailing.equalTo(contentView).offset(-16)
            }
            lastView = colorPickerBackground
        }
        if colorPickerForeground.superview != nil {
            colorPickerForeground.snp.makeConstraints { make in
                make.top.equalTo(lastView.snp.bottom).offset(20)
                make.leading.equalTo(contentView).offset(16)
                make.trailing.equalTo(contentView).offset(-16)
            }
            contentView.snp.makeConstraints { make in
                make.bottom.equalTo(colorPickerForeground.snp.bottom).offset(20)
            }
        } else {
            contentView.snp.makeConstraints { make in
                make.bottom.equalTo(lastView.snp.bottom).offset(20)
            }
        }
    }
    
    @objc
    private func hideKeyboard() {
        view.endEditing(true)
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
            scrollView.contentInset.bottom = keyboardHeight
            scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
            
            if let activeTextField = inputTextFields.first(where: { $0.input.textField.isFirstResponder })?.input {
                scrollView.scrollRectToVisible(activeTextField.frame, animated: true)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    private func setupActions() {
        inputTextFields.forEach { $0.input.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged) }
    }
    
    @objc private func textFieldDidChange() {
        updateQRCode()
    }
    
    @objc private func colorChanged() {
        updateQRCode()
    }
    
    private func updateQRCode() {
        let content = generateContent()
        if let qrCodeData = QRGenerator.generateQRCode(from: content, backgroundColor: selectedBackgroundColor ?? .white, foregroundColor: selectedForegroundColor ?? .black), let image = UIImage(data: qrCodeData) {
            qrCodePreview.setQRImage(image)
        }
    }
    
    private func generateContent() -> String {
        switch qrCodeType {
        case .text:
            return inputTextFields.first(where: { $0.field == .text })?.input.text ?? ""
        case .wifi:
            let ssid = inputTextFields.first(where: { $0.field == .networkName })?.input.text ?? ""
            let password = inputTextFields.first(where: { $0.field == .networkPassword })?.input.text ?? ""
            return "WIFI:T:WPA;S:\(ssid);P:\(password);;"
        case .url:
            return inputTextFields.first(where: { $0.field == .url })?.input.text ?? ""
        case .contact:
            let name = inputTextFields.first(where: { $0.field == .contactName })?.input.text ?? ""
            let phone = inputTextFields.first(where: { $0.field == .contactNumber })?.input.text ?? ""
            let email = inputTextFields.first(where: { $0.field == .contactMail })?.input.text ?? ""
            let url = inputTextFields.first(where: { $0.field == .contactURL })?.input.text ?? ""
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
    
    private func configureWithItem() {
        guard let item else { return }
        item.qrCodeType.inputFields.forEach { field in
            inputTextFields.first(where: { $0.field == field.fieldType })?.input.setText(field.value)
        }
        if let qrImage = UIImage(data: item.qrImageData) {
            qrCodePreview.setQRImage(qrImage)
        }
        if item.qrCodeType.isWifi, let wifiType = item.qrCodeType.wifiType {
            wifiTypeSegment.selectedSegmentIndex = WifiQRModel.WifiType.allCases.firstIndex(of: wifiType) ?? 0
        }
        switch qrCodeType {
        case .text(let model):
            if let backgroundHexColor = model?.backgroundHexColor {
                selectedBackgroundColor = UIColor.colorWithHexString(hexString: backgroundHexColor)
            }
            if let foregroundHexColor = model?.foregroundHexColor {
                selectedForegroundColor = UIColor.colorWithHexString(hexString: foregroundHexColor)
            }
        case .wifi(let model):
            if let backgroundHexColor = model?.backgroundHexColor {
                selectedBackgroundColor = UIColor.colorWithHexString(hexString: backgroundHexColor)
            }
            if let foregroundHexColor = model?.foregroundHexColor {
                selectedForegroundColor = UIColor.colorWithHexString(hexString: foregroundHexColor)
            }
        case .url(let model):
            if let backgroundHexColor = model?.backgroundHexColor {
                selectedBackgroundColor = UIColor.colorWithHexString(hexString: backgroundHexColor)
            }
            if let foregroundHexColor = model?.foregroundHexColor {
                selectedForegroundColor = UIColor.colorWithHexString(hexString: foregroundHexColor)
            }
        case .contact(let model):
            if let backgroundHexColor = model?.backgroundHexColor {
                selectedBackgroundColor = UIColor.colorWithHexString(hexString: backgroundHexColor)
            }
            if let foregroundHexColor = model?.foregroundHexColor {
                selectedForegroundColor = UIColor.colorWithHexString(hexString: foregroundHexColor)
            }
        }
        
        if editingItem {
            if let selectedBackgroundColor {
                colorPickerBackground.updateSelectedColor(selectedBackgroundColor)
            }
            if let selectedForegroundColor {
                colorPickerForeground.updateSelectedColor(selectedForegroundColor)
            }
        } else {
            updateQRCode()
        }
    }
    
    
    private let disposeBag = DisposeBag()
    private func bindModel() {
        wifiTypeSegment.rx.selectedSegmentIndex
            .subscribe(onNext: { [weak self] index in
                guard let self, let name = wifiTypeSegment.titleForSegment(at: index) else { return }
                
                var currentType: WifiQRModel.WifiType?
                if name == "FREE" {
                    currentType = .free
                } else if let value = WifiQRModel.WifiType(rawValue: name) {
                    currentType = value
                }
                if let currentType {
                    qrDataProcessor.wifiModel?.type = currentType
                }
            })
            .disposed(by: disposeBag)
        inputTextFields.forEach { item in
            switch item.field {
            case .text:
                item.input.textField
                    .rx
                    .text
                    .subscribe(onNext: { [weak self] text in
                        guard let text else { return }
                        self?.qrDataProcessor.textModel?.text = text
                    })
                    .disposed(by: disposeBag)
            case .networkName:
                item.input.textField
                    .rx
                    .text
                    .subscribe(onNext: { [weak self] text in
                        guard let text else { return }
                        self?.qrDataProcessor.wifiModel?.name = text
                    })
                    .disposed(by: disposeBag)

            case .networkPassword:
                item.input.textField
                    .rx
                    .text
                    .subscribe(onNext: { [weak self] text in
                        guard let text else { return }
                        self?.qrDataProcessor.wifiModel?.password = text
                    })
                    .disposed(by: disposeBag)
            case .url:
                item.input.textField
                    .rx
                    .text
                    .subscribe(onNext: { [weak self] text in
                        guard let text else { return }
                        self?.qrDataProcessor.urlModel?.url = text
                    })
                    .disposed(by: disposeBag)
            case .contactName:
                item.input.textField
                    .rx
                    .text
                    .subscribe(onNext: { [weak self] text in
                        guard let text else { return }
                        self?.qrDataProcessor.contactModel?.name = text
                    })
                    .disposed(by: disposeBag)
            case .contactNumber:
                item.input.textField
                    .rx
                    .text
                    .subscribe(onNext: { [weak self] text in
                        guard let text else { return }
                        self?.qrDataProcessor.contactModel?.phone = text
                    })
                    .disposed(by: disposeBag)
            case .contactMail:
                item.input.textField
                    .rx
                    .text
                    .subscribe(onNext: { [weak self] text in
                        guard let text else { return }
                        self?.qrDataProcessor.contactModel?.mail = text
                    })
                    .disposed(by: disposeBag)
            case .contactURL:
                item.input.textField
                    .rx
                    .text
                    .subscribe(onNext: { [weak self] text in
                        guard let text else { return }
                        self?.qrDataProcessor.contactModel?.url = text
                    })
                    .disposed(by: disposeBag)
            }
        }
    }
}

extension QRCodeCreatorViewController {
    func shareQRCode() {
        guard let qrImage = qrCodePreview.getQRCodeImage() else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [qrImage], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList
        ]
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    func saveQRCodeToGallery(completion: @escaping (Bool, Error?) -> Void) {
        guard let qrImage = qrCodePreview.getQRCodeImage() else {
            completion(false, nil)
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(qrImage, nil, nil, nil)
                completion(true, nil)
            } else {
                completion(false, NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access to photo library is not authorized."]))
            }
        }
    }
}
