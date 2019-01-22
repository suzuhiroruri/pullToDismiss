//
//  PullToDismissConfig.swift
//  pullToClose
//
//  Created by hir-suzuki on 2019/01/21.
//  Copyright © 2019年 hir-suzuki. All rights reserved.
//

import Foundation

class Config {
    static let shared: Config = Config()
    
    var backgroundEffect: BackgroundEffect? = ShadowEffect.default
    var dismissableHeightPercentage = PullToDismiss.Defaults.dismissableHeightPercentage
    
    func adaptSetting(pullToDismiss: PullToDismiss?) {
        pullToDismiss?.dismissableHeightPercentage = 50.0
        pullToDismiss?.backgroundEffect = ShadowEffect(color: .black, alpha: 0.7)
    }
}
