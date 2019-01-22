//
//  ModalViewController.swift
//  pullToClose
//
//  Created by hir-suzuki on 2019/01/21.
//  Copyright © 2019年 hir-suzuki. All rights reserved.
//

import UIKit
protocol ModalViewControllerProtocol:class {
    func dismiss()
}


class ModalViewController: UIViewController {
    private var pullToDismiss: PullToDismiss?
    var disissBlock: (() -> Void)?
    @IBOutlet var tableView: UITableView!
    @IBOutlet var customNavigationView: NavView!
    @IBOutlet var backgroundView: UIView!

    var isTop = true

    
    weak var delegate:ModalViewControllerProtocol?
    
    var viewHeight:CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        pullToDismiss = PullToDismiss(scrollView: tableView, viewController: self, navigationBar: customNavigationView)
        Config.shared.adaptSetting(pullToDismiss: pullToDismiss)
        pullToDismiss?.dismissAction = { [weak self] in
            self?.dismiss(nil)
        }
        pullToDismiss?.delegate = self
        
        
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        let myBoundHeight: CGFloat = UIScreen.main.bounds.size.height
        viewHeight = myBoundHeight - statusBarHeight
        
        backgroundView.alpha = 0.9
    }
    
    
    
    @IBAction func tapCloseButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func dismiss(_: AnyObject?) {
        self.delegate?.dismiss()
        dismiss(animated: true) { [weak self] in
            self?.disissBlock?()
            
        }
    }
}

extension ModalViewController:UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = indexPath.row.description
        return cell
    }
}


extension ModalViewController:UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if tableView.contentOffset.y == 0.0 {
            isTop = true
        } else {
            isTop = false
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isTop == true else {
            return
        }
        guard let globalPoint = customNavigationView.superview?.convert(customNavigationView.frame.origin, to: nil).y else {
            return
        }
        let scrollRate = globalPoint / viewHeight
        let alpha = 0.9 - scrollRate*2
        backgroundView.alpha = alpha
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        backgroundView.alpha = 0.9
    }
    
}
