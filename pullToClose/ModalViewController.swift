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
    private var pullToDismiss: PullToDismiss?
    var dimissBlock: (() -> Void)?
    @IBOutlet var tableView: UITableView!
    @IBOutlet var customNavigationView: NavView!
    @IBOutlet var backgroundView: UIView!

    @IBOutlet var backgroundViewHeight: NSLayoutConstraint!
    private var isTop = true

    weak var delegate: ModalViewControllerProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        pullToDismiss = PullToDismiss(scrollView: tableView, viewController: self, navigationBar: customNavigationView)
        Config.shared.adaptSetting(pullToDismiss: pullToDismiss)
        pullToDismiss?.dismissAction = { [weak self] in
            self?.dismiss()
        }
        pullToDismiss?.delegate = self

        // 背景のビュー設定
        backgroundViewHeight.constant = UIScreen.main.bounds.size.height*2
        backgroundView.alpha = 0.7

        customNavigationView?.navViewDelegate = self
    }

    /// 画面閉じる
    @objc func dismiss() {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.backgroundView.alpha = 0.0
        })
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

extension ModalViewController: UIScrollViewDelegate {

    /// スクロールを開始
    ///
    /// - Parameter scrollView: scrollView
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if tableView.contentOffset.y == 0.0 {
            isTop = true
        } else {
            isTop = false
        }
    }

    /// スクロール中
    ///
    /// - Parameter scrollView: scrollView
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isTop == true else {
            return
        }
        guard let globalPoint = customNavigationView.superview?.convert(customNavigationView.frame.origin, to: nil).y else {
            return
        }
        let scrollRate = globalPoint / UIScreen.main.bounds.size.height
        let alpha = 0.7 - scrollRate*2
        backgroundView.alpha = alpha
    }

    /// スクロール終了(指が離れた瞬間)
    ///
    /// - Parameters:
    ///   - scrollView: scrollView
    ///   - decelerate: 慣性が効いているかどうか
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        backgroundView.alpha = 0.7
    }
}

extension ModalViewController: NavViewDelegate {
    /// 閉じるボタンをタップ
    func tapCloseButton() {
        self.dismiss()
    }
}
