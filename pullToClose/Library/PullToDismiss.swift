//
//  PullToDismiss.swift
//  PullToDismiss
//
//  Created by Suguru Kishimoto on 11/13/16.
//  Copyright © 2016 Suguru Kishimoto. All rights reserved.
//

import Foundation
import UIKit

open class PullToDismiss: NSObject {

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

    private var __scrollView: UIScrollView?

    private var proxy: ScrollViewDelegateProxy? {
        didSet {
            __scrollView?.delegate = proxy
        }
    }

    private var panGesture: UIPanGestureRecognizer?
    private var backgroundView: UIView?
    private var navigationBarHeight: CGFloat = 0.0
    private var blurSaturationDeltaFactor: CGFloat = 1.8
    convenience public init?(scrollView: UIScrollView) {
        guard let viewController = type(of: self).viewControllerFromScrollView(scrollView) else {
            print("a scrollView must be on the view controller.")
            return nil
        }
        self.init(scrollView: scrollView, viewController: viewController)
    }

    public init(scrollView: UIScrollView, viewController: UIViewController, navigationBar: UIView? = nil) {
        super.init()
        self.proxy = ScrollViewDelegateProxy(delegates: [self])
        self.__scrollView = scrollView
        self.__scrollView?.delegate = self.proxy
        self.viewController = viewController
        self.__scrollView?.bounces = true
        
        if let navigationBar = navigationBar ?? viewController.navigationController?.navigationBar {
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            navigationBar.addGestureRecognizer(gesture)
            self.navigationBarHeight = navigationBar.frame.height
            self.panGesture = gesture
        }
    }
    
    var isTop = true
    var isFirst = true
    deinit {
        if let panGesture = panGesture {
            panGesture.view?.removeGestureRecognizer(panGesture)
        }

        proxy = nil
        __scrollView?.delegate = nil
        __scrollView = nil
    }

    fileprivate var targetViewController: UIViewController? {
        return viewController?.navigationController ?? viewController
    }

    fileprivate func dismiss() {
        targetViewController?.dismiss(animated: true, completion: nil)
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

    fileprivate func startDragging() {
        if let scrollView = __scrollView {
            if scrollView.contentOffset.y <= CGFloat(0) {
                isTop = true
            } else {
                isTop = false
            }
        }
        
        targetViewController?.view.layer.removeAllAnimations()
        backgroundView?.layer.removeAllAnimations()
        viewPositionY = 0.0
    }

    fileprivate func updateViewPosition(offset: CGFloat) {
        if !isTop {
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
        if dragging && isTop {
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
