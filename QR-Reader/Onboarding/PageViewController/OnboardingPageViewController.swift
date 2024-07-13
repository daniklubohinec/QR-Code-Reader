//
//  OnboardingPageViewController.swift
//  QR-Reader
//
//  Created by Danik Lubohinec on 12.07.24.
//

import UIKit
import RxSwift
import RxCocoa

class OnboardingPageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIScrollViewDelegate {
    
    let disposeBag = DisposeBag()
    
    var viewControllerIndex: Int!
    var onboardingViewController: OnboardingViewController!
    weak var parentVC: UIViewController?
    private var previousIndex = 0
    
    lazy var orderedViewControllers: [UIViewController] = {
        return [
            R.storyboard.onboarding.firstOnboardViewController()!,
            R.storyboard.onboarding.secondOnboardViewController()!,
            R.storyboard.onboarding.thirdOnboardViewController()!,
            R.storyboard.onboarding.fourthOnboardViewController()!,
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        dataSource = self
        
        if let scrollView = (view.subviews.filter { $0 is UIScrollView }.first) as? UIScrollView {
            scrollView.delegate = self
        }
        
        setViewControllers([orderedViewControllers[0]], direction: .forward, animated: true, completion: nil)
        
        onboardingViewController.segmentChanged
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { [weak self] value in
                guard let strongSelf = self else { return }
                strongSelf.setViewControllers([strongSelf.orderedViewControllers[value]], direction: .forward, animated: true, completion: nil)
                strongSelf.previousIndex = value
            })
            .disposed(by: disposeBag)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let pageContentViewController = pageViewController.viewControllers else { return }
        guard let first = pageContentViewController.first else { return }
        guard let index = orderedViewControllers.firstIndex(of: first) else { return }
        onboardingViewController.currentIndex = index
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        viewControllerIndex = orderedViewControllers.firstIndex(of: viewController)
        
        let previousIndex = viewControllerIndex - 1
        // User is on the first view controller and swiped left to loop to
        // the last view controller.
        guard previousIndex >= 0 else {
            // return orderedViewControllers.last
            // Uncommment the line below, remove the line above if you don't want the page control to loop.
            return nil
        }
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        viewControllerIndex = orderedViewControllers.firstIndex(of: viewController)
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        // User is on the last view controller and swiped right to loop to
        // the first view controller.
        guard orderedViewControllersCount != nextIndex else {
            // return orderedViewControllers.first
            // Uncommment the line below, remove the line above if you don't want the page control to loop.
            return nil
        }
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        return orderedViewControllers[nextIndex]
    }
}
