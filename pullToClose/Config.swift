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

    var dismissableHeightPercentage = PTDPullToDismiss.Defaults.dismissableHeightPercentage

    func adaptSetting(pullToDismiss: PTDPullToDismiss?) {
        pullToDismiss?.dismissableHeightPercentage = dismissableHeightPercentage
    }
}
