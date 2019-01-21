//
//  BackgroundEffect.swift
//  PullToDismiss
//
//  Created by Suguru Kishimoto on 12/3/16.
//  Copyright © 2016 Suguru Kishimoto. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol BackgroundEffect: NSObjectProtocol {
    var color: UIColor? { get set }
    var alpha: CGFloat { get set }
    var target: BackgroundTarget { get }
    
    func makeBackgroundView() -> UIView
    func applyEffect(view: UIView?, rate: CGFloat)
}

/// A target type to add background view
///
/// - targetViewController: add background view to target viewcontroller
/// - presentingViewController: add background view to target viewcontroller's presenting viewcontroller
@objc public enum BackgroundTarget: Int {
    case targetViewController
    case presentingViewController
}

public final class ShadowEffect: NSObject, BackgroundEffect {
    public var color: UIColor?
    public var alpha: CGFloat
    public var target: BackgroundTarget = .targetViewController

    @objc(defaultShadowEffedt)
    public static let `default`: ShadowEffect = ShadowEffect(color: .black, alpha: 0.8)
    
    public init(color: UIColor?, alpha: CGFloat) {
        self.color = color
        self.alpha = alpha
    }
    
    // only Objective-C
    @available(*, unavailable)
    public class func shadowEffect(color: UIColor?, alpha: CGFloat) -> ShadowEffect {
        return ShadowEffect(color: color, alpha: alpha)
    }
    
    
    public func makeBackgroundView() -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = color
        view.alpha = alpha
        return view
    }
    
    public func applyEffect(view: UIView?, rate: CGFloat) {
        view?.alpha = alpha * rate
    }
}
