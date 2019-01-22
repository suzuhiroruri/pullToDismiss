//
//  PullToDismiss.swift
//  PullToDismiss
//
//  Created by hir-suzuki on 2019/01/21.
//  Copyright © 2019年 hir-suzuki. All rights reserved.
//

import Foundation
import UIKit

open class PullToDismiss: NSObject {

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
            proxy = ScrollViewDelegateProxy(delegates: delegates)
        }
    }
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

    private var proxy: ScrollViewDelegateProxy? {
        didSet {
            scrollView?.delegate = proxy
        }
    }

    private var panGesture: UIPanGestureRecognizer?
    private var navigationBarHeight: CGFloat = 0.0

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
        self.proxy = ScrollViewDelegateProxy(delegates: [self])
        self.scrollView = scrollView
        self.scrollView?.delegate = self.proxy
        self.viewController = viewController
        self.scrollView?.bounces = true

        if let navigationBar = navigationBar ?? viewController.navigationController?.navigationBar {
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            navigationBar.addGestureRecognizer(gesture)
            self.navigationBarHeight = navigationBar.frame.height
            self.panGesture = gesture
        }
    }

    var cancelUpdatePositionFlag = false

    deinit {
        if let panGesture = panGesture {
            panGesture.view?.removeGestureRecognizer(panGesture)
        }

        proxy = nil
        scrollView?.delegate = nil
        scrollView = nil
    }

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
                cancelUpdatePositionFlag = false
            } else {
                cancelUpdatePositionFlag = true
            }
        }

        targetViewController?.view.layer.removeAllAnimations()
        viewPositionY = 0.0
    }

    /// Viewの位置更新
    ///
    /// - Parameter offset: 移動させる分のOffset
    fileprivate func updateViewPosition(offset: CGFloat) {
        if cancelUpdatePositionFlag {
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
    /// - Parameter velocity: スクロールの速度
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

extension PullToDismiss: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if dragging && !cancelUpdatePositionFlag {
            let diff = -(scrollView.contentOffset.y - previousContentOffsetY)
            if scrollView.contentOffset.y < -scrollView.contentInset.top || (targetViewController?.view.frame.origin.y ?? 0.0) > 0.0 {
                updateViewPosition(offset: diff)
                scrollView.contentOffset.y = -scrollView.contentInset.top
            }
            previousContentOffsetY = scrollView.contentOffset.y
        }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startDragging()
        dragging = true
        previousContentOffsetY = scrollView.contentOffset.y
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        finishDragging(withVelocity: velocity)
        dragging = false
        previousContentOffsetY = 0.0
    }
}
