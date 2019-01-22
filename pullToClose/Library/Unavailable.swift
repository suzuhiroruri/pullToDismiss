//
//  Unavailable.swift
//  PullToDismiss
//
//  Created by hir-suzuki on 2019/01/21.
//  Copyright © 2019年 hir-suzuki. All rights reserved.
//

import Foundation
import UIKit

extension PullToDismiss {
    @available(*, unavailable, renamed: "delegate")
    public weak var delegateProxy: AnyObject? {
        fatalError("\(#function) is no longer available")
    }

    @available(*, unavailable, message: "unavailable")
    public weak var scrollViewDelegate: UIScrollViewDelegate? {
        fatalError("\(#function) is no longer available")
    }

    @available(*, unavailable, message: "unavailable")
    public weak var tableViewDelegate: UITableViewDelegate? {
        fatalError("\(#function) is no longer available")
    }

    @available(*, unavailable, message: "unavailable")
    public weak var collectionViewDelegate: UICollectionViewDelegate? {
        fatalError("\(#function) is no longer available")
    }

    @available(*, unavailable, message: "unavailable")
    public weak var collectionViewDelegateFlowLayout: UICollectionViewDelegateFlowLayout? {
        fatalError("\(#function) is no longer available")
    }
}
