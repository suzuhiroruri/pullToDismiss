//
//  ModalViewController.swift
//  pullToClose
//
//  Created by hir-suzuki on 2019/01/21.
//  Copyright © 2019年 hir-suzuki. All rights reserved.
//

import UIKit

class ModalViewController: UIViewController {
    @IBOutlet var customNavigationView: UIView!
    
    @IBOutlet var cardView: UIView!
    private var pullToDismiss: PullToDismiss?
    var disissBlock: (() -> Void)?
    
    @IBOutlet var barImage: UIImageView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var tableView: UITableView!
    
    var isTop = true
    
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
        
        //右上と左下を角丸にする設定
        cardView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: cardView.frame.height)
        let path = UIBezierPath(roundedRect: cardView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 15, height: 15))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        cardView.layer.mask = mask
        
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        let myBoundHeight: CGFloat = UIScreen.main.bounds.size.height
        viewHeight = myBoundHeight - statusBarHeight
        
        barImage.image = barImage.image!.withRenderingMode(.alwaysTemplate)
        barImage.tintColor = UIColor.gray
        
        backgroundView.alpha = 0.9
    }
    
    @IBAction func tapCloseButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func dismiss(_: AnyObject?) {
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
