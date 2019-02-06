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
    public var dismissableHeightPercentage: CGFloat = 0.0 {
        didSet {
            dismissableHeightPercentage = min(max(0.0, dismissableHeightPercentage), 1.0)
        }
    }
    
    
    /// 背景ビュー
    public var backgroundView:UIView?
    
    /// モーダルviewの位置移動のフラグ
    private var updatePositionFlag = false
    
    /// モーダルビューの位置
    fileprivate var viewPositionY: CGFloat = 0.0
    
    /// 以前のモーダルビューのOffsetの値
    fileprivate var previousContentOffsetY: CGFloat = 0.0
    
    /// pullToDismissさせるviewController
    fileprivate var targetViewController: UIViewController?
    
    /// pullToDismissさせるviewControllerの中にあるscrollView
    private var insideScrollView: UIScrollView?
    
    /// pullToDismissさせるviewControllerの中にあるscrollViewをスクロールした時のフラグ
    private var scrollingInsideScrollViewFlag:Bool = false
    
    /// pullToDismissさせるviewControllerの中にあるscrollViewのスクロール開始時にスクロールがTopかどうかのフラグ
    private var insideScrollViewBeginDraggingTopFlag:Bool = false
    
    /// スクロールのプロキシ
    private var proxy: PTDScrollViewDelegateProxy? {
        didSet {
            insideScrollView?.delegate = proxy
        }
    }
    
    /// 初期化
    ///
    /// - Parameters:
    ///   - scrollView: scrollView
    ///   - viewController: pullToDismissさせるViewController
    public init(scrollView: UIScrollView, viewController: UIViewController) {
        super.init()
        self.proxy = PTDScrollViewDelegateProxy(delegates: [self])
        insideScrollView = scrollView
        insideScrollView?.delegate = self.proxy
        targetViewController = viewController
        
        let boundSize = UIScreen.main.bounds
        // 背景のビュー設定
        let backgroundViewFrame = CGRect(x: 0, y: -boundSize.height, width: boundSize.width, height: boundSize.height*2)
        self.backgroundView = UIView.init(frame: backgroundViewFrame)
        guard let backgroundView = self.backgroundView else {
            return
        }
        backgroundView.backgroundColor = UIColor.black
        backgroundView.alpha = 0.7
        targetViewController?.view.addSubview(backgroundView)
        targetViewController?.view.sendSubview(toBack: backgroundView)
    }
    
    deinit {
        proxy = nil
        insideScrollView?.delegate = nil
        insideScrollView = nil
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
        
        if scrollingInsideScrollViewFlag {
            if let scrollView = insideScrollView {
                if scrollView.contentOffset.y <= CGFloat(0) {
                    updatePositionFlag = true
                } else {
                    updatePositionFlag = false
                }
            }
        } else {
            updatePositionFlag = true
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
            guard let backgroundView = self.backgroundView else {
                return
            }
            backgroundView.alpha = 0.7
        }
        viewPositionY = 0.0
    }
    
    /// モーダルを閉じる
    private func dismiss() {
        targetViewController?.dismiss(animated: true, completion: nil)
    }
}

extension PTDPullToDismiss: UIScrollViewDelegate {
    /// スクロールを検知した瞬間
    ///
    /// - Parameter scrollView: scrollView
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == insideScrollView {
            scrollingInsideScrollViewFlag = true
            if scrollView.contentOffset.y == 0.0 {
                insideScrollViewBeginDraggingTopFlag = true
            } else {
                insideScrollViewBeginDraggingTopFlag = false
            }
        }
        startDragging()
        previousContentOffsetY = scrollView.contentOffset.y
    }
    
    /// スクロール中
    ///
    /// - Parameter scrollView: scrollView
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 下記の条件を全て満たす場合、指を離すまではモーダルビューは動かさないようにする
        // ・スクロール検知時にinsideScrollViewのスクロール位置がtopではなかった
        // ・モーダルビュー自体のスクロールは発生していない
        // ・上スクロールを行なった
        if insideScrollViewBeginDraggingTopFlag == false && targetViewController?.view.frame.origin.y == 0.0 && previousContentOffsetY < scrollView.contentOffset.y {
            updatePositionFlag = false
        }
        
        if updatePositionFlag {
            let diff = -(scrollView.contentOffset.y - previousContentOffsetY)
            if scrollView.contentOffset.y < -scrollView.contentInset.top || (targetViewController?.view.frame.origin.y ?? 0.0) > 0.0 {
                updateViewPosition(offset: diff)
                scrollView.contentOffset.y = -scrollView.contentInset.top
            }
            previousContentOffsetY = scrollView.contentOffset.y
            
            guard let globalPoint = targetViewController?.view.frame.origin.y else {
                return
            }
            let scrollRate = globalPoint / UIScreen.main.bounds.size.height
            let alpha = 0.7 - scrollRate*2
            guard let backgroundView = self.backgroundView else {
                return
            }
            backgroundView.alpha = alpha
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
        previousContentOffsetY = 0.0
        scrollingInsideScrollViewFlag = false
    }
}
