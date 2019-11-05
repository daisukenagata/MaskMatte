//
//  TabBarController.swift
//  SampleText+Navi
//
//  Created by 永田大祐 on 2019/11/05.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        UITabBar.appearance().tintColor = UIColor.black
        let item = UITabBarItem.appearance()
        item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)
        item.setTitleTextAttributes([kCTFontAttributeName as NSAttributedString.Key: UIFont.systemFont(ofSize: 0)], for: .normal)
        self.tabBar.frame.size = self.tabBar.sizeThatFits(CGSize(width: self.tabBar.frame.height, height: 100))
    }

}

extension UITabBar {
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        var sized = super.sizeThatFits(size)
        sized.height = 100
        return sized
    }
}
