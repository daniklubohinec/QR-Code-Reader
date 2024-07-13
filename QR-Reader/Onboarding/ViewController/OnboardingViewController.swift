//
//  OnboardingViewController.swift
//  QR-Reader
//
//  Created by Danik Lubohinec on 12.07.24.
//

import UIKit
import RxSwift
import RxCocoa

class OnboardingViewController: UIViewController {
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var nextPageButton: UIButton!
    
    let disposeBag = DisposeBag()
    
    public let segmentChanged = PublishSubject<Int>.init()
    
    var currentIndex: Int = 0 {
        didSet {
            setCurrentSegment(currentIndex)
            pageControl.currentPage = currentIndex
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindButtons()
        setupInterface()
    }
    
    func setupInterface() {
        guard !UserDefaults.standard.bool(forKey: "onboardingShown") else { return }
    }
    
    func bindButtons() {
        nextPageButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }
                if strongSelf.currentIndex <= 3 {
                    strongSelf.currentIndex += 1
                } else {
                    UserDefaults.standard.set(true, forKey: "onboardingShown")
                    // strongSelf.presentLogIn()
                }
            })
            .disposed(by: disposeBag)
    }
    
//    func presentLogIn() {
//        guard let logInVC = R.storyboard.logIn.logInViewController() else { return }
//        logInVC.modalPresentationStyle = .fullScreen
//        logInVC.modalTransitionStyle = .crossDissolve
//        self.present(logInVC, animated: true, completion: nil)
//    }
    
    func combineTapAndReference(_ button: UIButton) -> Observable<(Void, UIButton)> {
        return Observable.combineLatest(button.rx.tap, Observable.just(button))
    }
    
    // Segment button animation
    public func setCurrentSegment(_ segment: Int) {
        segmentChanged.onNext(segment)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let onboardingPageViewController = segue.destination as? OnboardingPageViewController else { return }
        onboardingPageViewController.onboardingViewController = self
        onboardingPageViewController.parentVC = self
    }
    
    deinit {
        print("----ONBOARDING----DEINIT-----")
    }
}
