//
//  ViewController.swift
//  pullToClose
//
//  Created by hir-suzuki on 2019/01/21.
//  Copyright © 2019年 hir-suzuki. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.style
    }
    var style:UIStatusBarStyle = .default
    
    func changeStyle(useDefault:Bool) {
        UIView.animate(withDuration: 0.25) {
            if useDefault {
                self.style = .default
            } else {
                self.style = .lightContent
            }
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    @IBAction func tapModalViewButton(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Modal", bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? ModalViewController else {
            return
        }
        vc.delegate = self
        changeStyle(useDefault: false)
        vc.modalPresentationStyle = .overCurrentContext
        self.navigationController?.navigationBar.barStyle = .black
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        self.present(vc, animated: true, completion: nil)
    }
}

extension ViewController:ModalViewControllerProtocol {
    func dismiss() {
        
       changeStyle(useDefault: true)
    }
}
