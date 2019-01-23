//
//  PTDCustomNavigationView.swift
//  pullToClose
//
//  Created by hir-suzuki on 2019/01/22.
//  Copyright © 2019年 hir-suzuki. All rights reserved.
//

import UIKit

protocol PTDCustomNavigationViewDelegate: class {
    func tapCloseButton()
}

class PTDCustomNavigationView: UIView {

    @IBOutlet var navigationTitle: UILabel!
    @IBOutlet var cardNavigation: UIView!
    @IBOutlet var controlBar: UIImageView!

    weak var delegate: PTDCustomNavigationViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        nibInit()
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        nibInit()
        commonInit()
    }

    // xibファイルを読み込んでviewに重ねる
    fileprivate func nibInit() {
        guard let view: UIView = Bundle.main.loadNibNamed("PTDCustomNavigationView", owner: self, options: nil)?.first as? UIView else {
            return
        }
        view.frame = self.bounds

        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        self.addSubview(view)
    }

    private func commonInit() {
        let boundWidth: CGFloat = UIScreen.main.bounds.size.width

        //右上と左上を角丸にする設定
        cardNavigation.frame = CGRect(x: 0, y: 0, width: boundWidth, height: cardNavigation.frame.height)
        let path = UIBezierPath(roundedRect: cardNavigation.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 15, height: 15))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        cardNavigation.layer.mask = mask

        guard let controlBarImage = controlBar.image else {
            return
        }
        controlBar.image = controlBarImage.withRenderingMode(.alwaysTemplate)
        controlBar.tintColor = UIColor.gray
    }

    /// 閉じるボタンをタップ
    ///
    /// - Parameter sender: sender
    @IBAction func tapCloseButton(_ sender: UIButton) {
        delegate?.tapCloseButton()
    }
}
