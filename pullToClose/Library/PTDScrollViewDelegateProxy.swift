//
//  PTDScrollViewDelegateProxy.swift
//  PullToDismiss
//
//  Created by hir-suzuki on 2019/01/21.
//  Copyright © 2019年 hir-suzuki. All rights reserved.
//

import Foundation
import UIKit

/// scrollViewのプロキシ
/// ModalViewで設定されたscrollViewのスクロールをpullToDismissに反映させる
class PTDScrollViewDelegateProxy: PTDDelegateProxy, UIScrollViewDelegate {
    @nonobjc convenience init(delegates: [UIScrollViewDelegate]) {
        self.init(__delegates: delegates)
    }
}
