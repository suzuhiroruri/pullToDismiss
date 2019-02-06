//
//  ModalViewController.swift
//  pullToClose
//
//  Created by hir-suzuki on 2019/01/21.
//  Copyright © 2019年 hir-suzuki. All rights reserved.
//

import UIKit

protocol ModalViewControllerProtocol: class {
    func dismiss()
}

class ModalViewController: UIViewController {
    
    var dismissBlock: (() -> Void)?
    @IBOutlet var tableView: UITableView!
    @IBOutlet var customNavigationView: PTDCustomNavigationView!
    
    private lazy var pullToDismiss: PTDPullToDismiss = {
        let pullToDismiss = PTDPullToDismiss(scrollView: tableView, viewController: self)
        pullToDismiss.dismissAction = { [weak self] in
            self?.dismiss()
        }
        pullToDismiss.delegate = self
        
        return pullToDismiss
    }()

    weak var delegate: ModalViewControllerProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        customNavigationView.navigationTitle.text = "タイトル"
        PTDConfig.shared.dismissableHeightPercentage = 0.3
        PTDConfig.shared.adaptSetting(pullToDismiss: pullToDismiss)
        

        customNavigationView?.delegate = self
    }

    /// 画面閉じる
    @objc func dismiss() {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.pullToDismiss.backgroundView?.alpha = 0.0
        })
        dismiss(animated: true) { [weak self] in
            self?.dismissBlock?()
        }
        self.delegate?.dismiss()
    }
}

extension ModalViewController: UITableViewDelegate, UITableViewDataSource {
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

extension ModalViewController: PTDCustomNavigationViewDelegate {
    /// 閉じるボタンをタップ
    func tapCloseButton() {
        self.dismiss()
    }
}
