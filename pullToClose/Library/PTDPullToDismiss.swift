//
//  PTDPullToDismiss.swift
//  PullToDismiss
//
//  Created by hir-suzuki on 2019/01/21.
//  Copyright © 2019年 hir-suzuki. All rights reserved.
//

import Foundation
import UIKit

open class PTDPullToDismiss: NSObject {

    /// デフォルト設定
    public struct Defaults {
        private init() {}
        public static let dismissableHeightPercentage: CGFloat = 0.33
    }

    public var dismissAction: (() -> Void)?
    public weak var delegate: UIScrollViewDelegate? {
        didSet {
            var delegates: [UIScrollViewDelegate] = [self]
            if let delegate = delegate {
                delegates.append(delegate)
            }
            proxy = PTDScrollViewDelegateProxy(delegates: delegates)
        }
    }

    /// モーダルを閉じる画面の閾値
    public var dismissableHeightPercentage: CGFloat = Defaults.dismissableHeightPercentage {
        didSet {
            dismissableHeightPercentage = min(max(0.0, dismissableHeightPercentage), 1.0)
        }
    }

    fileprivate var viewPositionY: CGFloat = 0.0
    fileprivate var dragging: Bool = false
    fileprivate var previousContentOffsetY: CGFloat = 0.0
    fileprivate weak var viewController: UIViewController?

    private var scrollView: UIScrollView?

    private var proxy: PTDScrollViewDelegateProxy? {
        didSet {
            scrollView?.delegate = proxy
        }
    }

    private var panGesture: UIPanGestureRecognizer?
    private var navigationBarHeight: CGFloat = 0.0

    /// モーダルviewの位置移動のフラグ
    private var updatePositionFlag = false

    /// pullToDismissさせるviewController
    fileprivate var targetViewController: UIViewController? {
        return viewController?.navigationController ?? viewController
    }

    fileprivate func dismiss() {
        targetViewController?.dismiss(animated: true, completion: nil)
    }

    /// 初期化
    ///
    /// - Parameters:
    ///   - scrollView: scrollView
    ///   - viewController: pullToDismissさせるViewController
    ///   - navigationBar: navigationBar
    public init(scrollView: UIScrollView, viewController: UIViewController, navigationBar: UIView? = nil) {
        super.init()
        self.proxy = PTDScrollViewDelegateProxy(delegates: [self])
        self.scrollView = scrollView
        self.scrollView?.delegate = self.proxy
        self.viewController = viewController

        if let navigationBar = navigationBar ?? viewController.navigationController?.navigationBar {
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            navigationBar.addGestureRecognizer(gesture)
            self.navigationBarHeight = navigationBar.frame.height
            self.panGesture = gesture
        }
    }

    deinit {
        if let panGesture = panGesture {
            panGesture.view?.removeGestureRecognizer(panGesture)
        }

        proxy = nil
        scrollView?.delegate = nil
        scrollView = nil
    }

    /// 引っ張る動作の処理
    ///
    /// - Parameter gesture: UIPanGestureRecognizer
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            startDragging()
        case .changed:
            let diff = gesture.translation(in: gesture.view).y
            updateViewPosition(offset: diff)
            gesture.setTranslation(.zero, in: gesture.view)
        case .ended:
          finishDragging(withVelocity: .zero)
        default:
            break
        }
    }

    /// ドラッグ開始
    fileprivate func startDragging() {
        if let scrollView = self.scrollView {
            if scrollView.contentOffset.y <= CGFloat(0) {
                updatePositionFlag = true
            } else {
                updatePositionFlag = false
            }
        }

        targetViewController?.view.layer.removeAllAnimations()
        viewPositionY = 0.0
    }

    /// モーダルビューの位置更新
    ///
    /// - Parameter offset: 移動させる分のOffset
    fileprivate func updateViewPosition(offset: CGFloat) {
        if !updatePositionFlag {
            return
        }

        var addOffset: CGFloat = offset
        // avoid statusbar gone
        if viewPositionY >= 0 && viewPositionY < 0.05 {
            addOffset = min(max(-0.01, addOffset), 0.01)
        }
        viewPositionY += addOffset
        targetViewController?.view.frame.origin.y = max(0.0, viewPositionY)
    }

    /// ドラッグ終了
    ///
    /// - Parameter velocity: ドラッグ終了時の位置
    fileprivate func finishDragging(withVelocity velocity: CGPoint) {
        let originY = targetViewController?.view.frame.origin.y ?? 0.0
        let dismissableHeight = (targetViewController?.view.frame.height ?? 0.0) * dismissableHeightPercentage
        if originY > dismissableHeight || originY > 0 && velocity.y < 0 {
            proxy = nil
            _ = dismissAction?() ?? dismiss()
        } else if originY != 0.0 {
            UIView.perform(.delete, on: [], options: [.allowUserInteraction], animations: { [weak self] in
                self?.targetViewController?.view.frame.origin.y = 0.0
            })
        }
        viewPositionY = 0.0
    }

    private static func viewControllerFromScrollView(_ scrollView: UIScrollView) -> UIViewController? {
        var responder: UIResponder? = scrollView
        while let r = responder {
            if let viewController = r as? UIViewController {
                return viewController
            }
            responder = r.next
        }
        return nil
    }
}

extension PTDPullToDismiss: UIScrollViewDelegate {
    /// スクロールを検知した瞬間
    ///
    /// - Parameter scrollView: scrollView
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startDragging()
        dragging = true
        previousContentOffsetY = scrollView.contentOffset.y
    }
    
    /// スクロール中
    ///
    /// - Parameter scrollView: scrollView
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 一旦モーダルビュー自体が動いていない状態で上スクロールした場合、指を離すまではモーダルは動かさないようにする
        if targetViewController?.view.frame.origin.y == 0.0 && previousContentOffsetY < scrollView.contentOffset.y {
            updatePositionFlag = false
        }

        if dragging && updatePositionFlag {
            let diff = -(scrollView.contentOffset.y - previousContentOffsetY)
            if scrollView.contentOffset.y < -scrollView.contentInset.top || (targetViewController?.view.frame.origin.y ?? 0.0) > 0.0 {
                updateViewPosition(offset: diff)
                scrollView.contentOffset.y = -scrollView.contentInset.top
            }
            previousContentOffsetY = scrollView.contentOffset.y
        }
    }

    /// ドラッグの終わりの始まり
    ///
    /// - Parameters:
    ///   - scrollView: scrollView
    ///   - velocity: 指を離した瞬間のスクロールビューの高さ
    ///   - targetContentOffset: スクロールの慣性がストップする想定のoffset
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        finishDragging(withVelocity: velocity)
        dragging = false
        previousContentOffsetY = 0.0
    }
}
