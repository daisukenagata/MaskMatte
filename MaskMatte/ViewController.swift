//
//  ViewController.swift
//  MaskMatte
//
//  Created by 永田大祐 on 2019/11/03.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

class ViewController: UIViewController {

    static func identifier() -> String { return String(describing: ViewController.self) }

    static func viewController() -> ViewController {

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateInitialViewController() as! ViewController
        return vc
    }

    private var maskPortraitMatte: MaskFilterBuiltinsMatte? = nil

    private var bView: ButtonView? = nil

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

        maskPortraitMatte = MaskFilterBuiltinsMatte()
        bView = ButtonView(frame: self.tabBarController?.tabBar.frame ?? CGRect())

        let d = UIView(frame: CGRect(x: 0, y: 44, width: self.view.frame.width, height: self.view.frame.height - 188))
        view.addSubview(d)

        self.tabBarController?.tabBar.addSubview(bView?.bt ?? UIButton())
        self.tabBarController?.tabBar.addSubview(bView?.bt2 ?? UIButton())
        maskPortraitMatte?.setMaskFilter(view: d)

        bView?.bt.addTarget(self, action: #selector(btAction), for: .touchUpInside)
        bView?.bt2.addTarget(self, action: #selector(cameraAction), for: .touchUpInside)
    }

    @objc func btAction() { maskPortraitMatte?.btAction(view: self.view) }

    @objc func cameraAction() { maskPortraitMatte?.uIImageWriteToSavedPhotosAlbum(imageView: maskPortraitMatte?.xibView?.sliderImageView ?? UIImageView()) }
}
