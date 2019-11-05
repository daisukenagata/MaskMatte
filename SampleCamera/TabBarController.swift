//
//  TabBarController.swift
//  SampleText+Navi
//
//  Created by 永田大祐 on 2019/11/05.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

    private var statusBarStyle : UIStatusBarStyle = .default

    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewControllers = TabBarController.viewControllers()
        
        UITabBar.appearance().tintColor = UIColor.black
        let item = UITabBarItem.appearance()
        item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)
        item.setTitleTextAttributes([kCTFontAttributeName as NSAttributedString.Key: UIFont.systemFont(ofSize: 0)], for: .normal)
        self.tabBar.frame.size = self.tabBar.sizeThatFits(CGSize(width: self.tabBar.frame.height, height: 100))

        let bt = UIButton()
        bt.frame = CGRect(x: self.tabBar.frame.width/2 - 25,
                          y: self.tabBar.frame.height/2 - 25, width: 50, height: 50)
        bt.backgroundColor = .red
        self.tabBar.addSubview(bt)
        bt.layer.cornerRadius = bt.frame.height/2
    }

    @objc func btAction() {
        print("123")
    }

    static func viewControllers() -> [UIViewController] {

        let vi = ViewController.viewController()
        vi.view.backgroundColor = UIColor.white
        let opc = UINavigationController(rootViewController: vi)
        return [opc]
    }
}

extension TabBarController{

    override var shouldAutorotate : Bool { return true }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {

        guard let selectedVC = self.selectedViewController  else { return UIInterfaceOrientationMask.portrait }

        guard let navigation = selectedVC as? UINavigationController else { return UIInterfaceOrientationMask.portrait }

        guard let current = navigation.viewControllers.last else { return UIInterfaceOrientationMask.portrait }

        if current is ViewController { return UIInterfaceOrientationMask.all }
        return.portrait
    }
}

extension UITabBar {
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        var sized = super.sizeThatFits(size)
        sized.height = 100
        return sized
    }
}
