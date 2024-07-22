import UIKit
import SnapKit
import RxSwift
import RxCocoa


// MARK: - FLAGS
var ninjamode = false
var hasSubscription = false
//

final class OnboardingViewController: UIViewController, UIScrollViewDelegate {

    private let scrollView = UIScrollView()

    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = R.color.accentColor()!
        control.pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.08)
        return control
    }()
    private lazy var continueButton: UIButton = {
        let button = UIButton()
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = R.color.accentColor()
        configuration.baseForegroundColor = .white
        configuration.title = "Continue"
        button.configuration = configuration
        button.clipsToBounds = true
        button.layer.cornerRadius = 15
        
        return button
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = R.font.interBold(size: 32)
        label.textColor = R.color.c030303()
        label.textAlignment = .center
        return label
    }()
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = R.font.interRegular(size: 14)
        label.textColor = ninjamode ? R.color.c030303()?.withAlphaComponent(0.3) : R.color.c030303()
        label.textAlignment = .center
        return label
    }()
    private lazy var subView: SubscriptionOptionView = {
        let view = SubscriptionOptionView()
        view.backgroundColor = R.color.accentColor()?.withAlphaComponent(0.1)
        view.isHidden = true
        return view
    }()
    private lazy var footer: UIView = {
        let view = UIView()
        view.isHidden = true
        
        let termOfUse = UIButton()
        termOfUse.setAttributedTitle(NSAttributedString(string: "Terms Of use", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue]), for: .normal)
        termOfUse.setTitleColor(R.color.c030303()!.withAlphaComponent(0.1), for: .normal)
        termOfUse.titleLabel?.font = R.font.interRegular(size: 14)
        termOfUse.addTarget(self, action: #selector(termsOfUseTapped), for: .touchUpInside)
        
        let restore = UIButton()
        restore.setAttributedTitle(NSAttributedString(string: "Restore", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue]), for: .normal)
        restore.setTitleColor(R.color.c030303()!.withAlphaComponent(0.1), for: .normal)
        restore.titleLabel?.font = R.font.interRegular(size: 14)
        restore.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)

        let privacy = UIButton()
        privacy.setAttributedTitle(NSAttributedString(string: "Privacy policy", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue]), for: .normal)
        privacy.setTitleColor(R.color.c030303()!.withAlphaComponent(0.1), for: .normal)
        privacy.titleLabel?.font = R.font.interRegular(size: 14)
        privacy.addTarget(self, action: #selector(privacyTapped), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [termOfUse, restore, privacy])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 20
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        return view
    }()
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        let image: UIImage? = {
            if ninjamode {
                return UIImage(named: "NinjaCross")
            }
            return UIImage(named: "Cross")
        }()
        button.isHidden = ninjamode
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(closeScreen), for: .touchUpInside)
        button.isHidden = true
        
        return button
    }()
    
    private var continueButtonTopLabelConstraint: Constraint?
    private var continueButtonTopViewConstraint: Constraint?
    
    private lazy var bottomContainerView: UIView = {
        let view = UIView()
        view.addSubview(pageControl)
        view.addSubview(titleLabel)
        view.addSubview(subView)
        view.addSubview(descriptionLabel)
        view.addSubview(continueButton)
        view.addSubview(footer)
        
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(26)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        subView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(62)
        }
        
        continueButton.snp.makeConstraints { make in
            continueButtonTopLabelConstraint = make.top.equalTo(descriptionLabel.snp.bottom).offset(12).constraint
            continueButtonTopViewConstraint = make.top.equalTo(subView.snp.bottom).offset(12).constraint
            make.top.equalTo(descriptionLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(60)
        }
        footer.snp.makeConstraints { make in
            make.top.equalTo(continueButton.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(48)
            make.trailing.equalToSuperview().offset(-48)
            make.bottom.equalToSuperview()
        }
        continueButtonTopViewConstraint?.isActive = false
        
        return view
    }()
    private let pages: [OnboardingPage]
    private lazy var pagesView: [UIView] = {
        return pages.compactMap { page in
            return OnboardingPageView(image: page.image, title: page.title, description: page.subtitle)
        }
    }()
    private let disposeBag = DisposeBag()

    init(pages: [OnboardingPage] = OnboardingPage.allCases) {
        self.pages = pages
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = R.color.cF1F1F1()

        setupScrollView()
        setupPageControl()
        setupContinueButton()
        titleLabel.text = OnboardingPage.reader.title
        descriptionLabel.text = OnboardingPage.reader.subtitle
        
        pageControl.isHidden = pages.count == 1
        footer.isHidden = !(pages.count == 1)
        if !ninjamode, pages.count == 1 {
            footer.isHidden = false
            subView.isHidden = false
            descriptionLabel.isHidden = true
            continueButtonTopLabelConstraint?.isActive = false
            closeButton.isHidden = false
            continueButtonTopViewConstraint?.isActive = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if ninjamode, pageControl.numberOfPages == 1  {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {
                self.closeButton.isHidden = false
            }
        }
    }

    private func setupScrollView() {
        view.addSubview(scrollView)
        view.addSubview(bottomContainerView)
        view.addSubview(closeButton)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(28)
            make.leading.equalToSuperview().offset(28)
            make.top.equalTo(view.snp.topMargin).offset(20)
        }
        bottomContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
            make.bottom.equalToSuperview().offset(-21)
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        var previousPage: UIView? = nil
        for page in pagesView {
            scrollView.addSubview(page)
            page.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.width.equalTo(view)
                if let previousPage = previousPage {
                    make.left.equalTo(previousPage.snp.right)
                } else {
                    make.left.equalToSuperview()
                }
            }
            previousPage = page
        }

        if let lastPage = pagesView.last {
            scrollView.snp.makeConstraints { make in
                make.right.equalTo(lastPage.snp.right)
            }
        }
    }

    private func setupPageControl() {
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
    }

    private func setupContinueButton() {
        continueButton.setTitle("Continue", for: .normal)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
    }

    private var scrolledByButton = false
    @objc private func continueButtonTapped() {
        let currentPage = pageControl.currentPage
        if currentPage < pages.count - 1 {
            scrolledByButton = true
            let nextPage = CGPoint(x: scrollView.bounds.width * CGFloat(currentPage + 1), y: 0)
            scrollView.setContentOffset(nextPage, animated: true)
            pageControl.currentPage = currentPage + 1
            updateLabels(page: currentPage + 1)
        } else {
            Storage.shared.onboardingShown = true
            // TODO: BUY SUBSCRIPTION
            dismiss(animated: true)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !scrolledByButton else {
            return
        }
        let pageIndex = round(scrollView.contentOffset.x / view.bounds.width)
        if pageControl.currentPage != Int(pageIndex) {
            updateLabels(page: Int(pageIndex))
        }
        pageControl.currentPage = Int(pageIndex)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if scrolledByButton {
            scrolledByButton = false
        }
    }
    
    private func updateLabels(page: Int) {
        guard let page = OnboardingPage(rawValue: page) else { return }
        animateTextChange(for: titleLabel, newText: page.title)
        animateTextChange(for: descriptionLabel, newText: page.subtitle)
        descriptionLabel.isHidden = page == .buy
        subView.isHidden = page != .buy
        continueButtonTopLabelConstraint?.isActive = page != .buy
        continueButtonTopViewConstraint?.isActive = page == .buy
        if page == .buy, !ninjamode {
            var configuration = continueButton.configuration
            configuration?.title = "Try my FREE TRIAL, then $6.99/week"
            configuration?.subtitle = "Auto renewable. Cancel anytime"
            configuration?.titleAlignment = .center
            configuration?.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ container in
                var container = container
                container.foregroundColor = UIColor.white.withAlphaComponent(0.4)
               return container
            })
            continueButton.configuration = configuration
            continueButton.updateConfiguration()
        } else {
            var configuration = UIButton.Configuration.filled()
            configuration.baseBackgroundColor = R.color.accentColor()
            configuration.baseForegroundColor = .white
            configuration.title = "Continue"
            continueButton.configuration = configuration
            continueButton.updateConfiguration()
        }
        
        pageControl.isHidden = page == .buy
        footer.isHidden = page != .buy
        if ninjamode, pageControl.numberOfPages == 1 || page == .buy {
            subView.isHidden = true
            descriptionLabel.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {
                self.closeButton.isHidden = false
            }
        } else {
            closeButton.isHidden = page != .buy
        }
    }

    private func animateTextChange(for label: UILabel, newText: String) {
        UIView.animate(withDuration: 0.35, animations: {
            label.alpha = 0
        }) { (completed) in
            label.text = newText
            UIView.animate(withDuration: 0.35, animations: {
                label.alpha = 1
            })
        }
    }
    
    @objc
    private func closeScreen() {
        dismiss(animated: true)
    }
    
    @objc private func termsOfUseTapped() {
        // TODO
    }
    
    @objc private func restoreTapped() {
        // TODO
    }

    @objc private func privacyTapped() {
        // TODO
    }

}

final class OnboardingPageView: UIView {

    init(image: UIImage?, title: String, description: String) {
        super.init(frame: .zero)

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(snp.topMargin)
            make.centerX.equalToSuperview()
            make.width.equalTo(358)
            make.height.equalTo(458)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SubscriptionOptionView: UIView {
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = R.color.accentColor()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let freeTrialLabel: UILabel = {
        let label = UILabel()
        label.text = "3 Days for Free"
        label.font = .systemFont(ofSize: 16)
        label.textColor = R.color.accentColor()
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.text = "then $6.99/week"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .black
        label.textAlignment = .right
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = R.color.accentColor()?.withAlphaComponent(0.1)
        layer.cornerRadius = 15

        addSubview(checkmarkImageView)
        addSubview(freeTrialLabel)
        addSubview(priceLabel)

        checkmarkImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(12)
            make.width.height.equalTo(24)
        }

        freeTrialLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(checkmarkImageView.snp.trailing).offset(8)
        }

        priceLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-12)
            make.leading.equalTo(freeTrialLabel.snp.trailing).offset(8)
        }
    }
    
    func configure(with price: String, duration: String) {
        priceLabel.text = price
        freeTrialLabel.text = duration
    }
}
