//
//  CreatedViewController.swift
//  QR-Reader
//
//  Created by Danik Lubohinec on 15.07.24.
//

import UIKit
import RxSwift

class CreatedViewController: UIViewController {
    
    @IBOutlet weak var hintStackView: UIStackView!
    
    @IBOutlet weak var createdTableView: UITableView!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
}
