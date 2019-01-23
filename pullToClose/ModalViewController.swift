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
    private var pullToDismiss: PTDPullToDismiss?
    var dimissBlock: (() -> Void)?
    @IBOutlet var tableView: UITableView!
    @IBOutlet var customNavigationView: PTDCustomNavigationView!

    weak var delegate: ModalViewControllerProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        customNavigationView.navigationTitle.text = "タイトル"
        pullToDismiss = PTDPullToDismiss(scrollView: tableView, viewController: self, navigationBar: customNavigationView)
        PTDConfig.shared.dismissableHeightPercentage = 80.0
        PTDConfig.shared.adaptSetting(pullToDismiss: pullToDismiss)
        pullToDismiss?.dismissAction = { [weak self] in
            self?.dismiss()
        }
        pullToDismiss?.delegate = self

        customNavigationView?.delegate = self
    }

    /// 画面閉じる
    @objc func dismiss() {
        dismiss(animated: true) { [weak self] in
            self?.dimissBlock?()
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
