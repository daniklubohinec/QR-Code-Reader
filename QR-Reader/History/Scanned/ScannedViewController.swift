//
//  ScannedViewController.swift
//  QR-Reader
//
//  Created by Danik Lubohinec on 15.07.24.
//

import UIKit
import RxSwift

class ScannedViewController: UIViewController {
    
    @IBOutlet weak var hintStackView: UIStackView!
    
    @IBOutlet weak var scannedTableView: UITableView!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
}
