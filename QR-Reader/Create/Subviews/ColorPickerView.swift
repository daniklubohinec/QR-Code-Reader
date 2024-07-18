import UIKit

class ColorPickerView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let colorStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()
    
    private let colorWell: UIColorWell = {
        let well = UIColorWell()
        well.supportsAlpha = false
        return well
    }()
    
    private var selectedColorButton: UIButton?
    private var onColorSelected: ((UIColor) -> Void)?
    
    private let colors: [UIColor] = [
        .black,
        .white,
        R.color.accentColor()!,
        R.color.ffcc00()!,
        R.color.ff3B30()!,
        R.color.c34C759()!
    ]
    
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 10
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        
        addSubview(titleLabel)
        addSubview(colorStackView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }
        
        colorStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
            make.height.equalTo(30)
        }
        
        setupColorButtons()
    }
    
    private func setupColorButtons() {
        colorWell.snp.makeConstraints { make in
            make.width.height.equalTo(30)
        }
        colorStackView.addArrangedSubview(colorWell)
        colorWell.addTarget(self, action: #selector(colorWellChanged), for: .valueChanged)
        
        for color in colors {
            let button = createButton(with: color)
            button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            colorStackView.addArrangedSubview(button)
            
            button.snp.makeConstraints { make in
                make.width.height.equalTo(30)
            }
        }
    }
    
    private func createButton(with color: UIColor) -> UIButton {
        let button = UIButton()
        button.backgroundColor = color
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.black.withAlphaComponent(0.08).cgColor
        button.clipsToBounds = true
        return button
    }
    
    @objc private func colorButtonTapped(_ sender: UIButton) {
        updateSelectedColor(sender.backgroundColor ?? .clear)
    }
    
    @objc private func colorWellChanged() {
        updateSelectedColor(colorWell.selectedColor ?? .clear)
    }
    
    func updateSelectedColor(_ color: UIColor) {
        selectedColorButton?.layer.borderColor = UIColor.black.withAlphaComponent(0.08).cgColor
        if let button = colorStackView.arrangedSubviews.first(where: { $0.backgroundColor == color }) as? UIButton {
            button.layer.borderWidth = 1
            button.layer.borderColor = R.color.accentColor()!.cgColor
            selectedColorButton = button
        } else {
            colorWell.selectedColor = color
        }
        onColorSelected?(color)
    }
    
    func setOnColorSelected(completion: @escaping (UIColor) -> Void) {
        onColorSelected = completion
    }
}
