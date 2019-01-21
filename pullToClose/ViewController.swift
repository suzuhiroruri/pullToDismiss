//
//  ViewController.swift
//  pullToClose
//
//  Created by hir-suzuki on 2019/01/21.
//  Copyright © 2019年 hir-suzuki. All rights reserved.
//

import UIKit
import PullToDismiss

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func tapModalViewButton(_ sender: UIButton) {
        let vc: UIViewController = { () -> UIViewController in
            let storyboard = UIStoryboard(name: "Modal", bundle: nil)
            guard let viewController = storyboard.instantiateInitialViewController() else {
                return UIViewController()
            }
            return viewController
        }()
        vc.modalPresentationStyle = .overCurrentContext
        self.present(vc, animated: true, completion: nil)
    }
}

