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

    private let maskPortraitMatte = MaskFilterBuiltinsMatte()
    
    private let xibView = SliiderObjects()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let d = UIView(frame: CGRect(x: 0, y: 44, width: self.view.frame.width, height: self.view.frame.height - 188))
        view.addSubview(d)
        maskPortraitMatte.setMaskFilter(view: d)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

        let bt = UIButton()
        bt.frame = CGRect(x: (self.tabBarController?.tabBar.frame.width ?? 0.0) / 2 - 75,
                          y: (self.tabBarController?.tabBar.frame.height ?? 0.0) / 2 - 25, width: 50, height: 50)
        bt.backgroundColor = .red
        self.tabBarController?.tabBar.addSubview(bt)
        bt.layer.cornerRadius = bt.frame.height/2
        bt.addTarget(self, action: #selector(btAction), for: .touchUpInside)
        
        let bt2 = UIButton()
        bt2.frame = CGRect(x: (self.tabBarController?.tabBar.frame.width ?? 0.0) / 2 + 25,
                          y: (self.tabBarController?.tabBar.frame.height ?? 0.0) / 2 - 25, width: 50, height: 50)
        bt2.backgroundColor = .blue
        self.tabBarController?.tabBar.addSubview(bt2)
        bt2.layer.cornerRadius = bt2.frame.height/2
        bt2.addTarget(self, action: #selector(cameraAction), for: .touchUpInside)
    }

    @objc func btAction() {
        if self.xibView.sliderImageView.image == nil {
        maskPortraitMatte.cameraAction { image in
            self.xibView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
            self.xibView.sliderImageView.contentMode = .scaleAspectFit
            self.xibView.sliderImageView.image = image
            self.xibView.sliderImageView.frame.origin.y = 0
            self.view.addSubview(self.xibView)
            }
        } else {
            maskPortraitMatte.maskFilterBuiltinsChanges(value    : xibView.sliderInputRVector.value,
                                                        value2   : xibView.sliderInputGVector.value,
                                                        value3   : xibView.sliderInputBVector.value,
                                                        value4   : xibView.sliderInputAVector.value,
                                                        photo    : maskPortraitMatte.photos,
                                                        ssmType  : maskPortraitMatte.semanticSegmentationType,
                                                        imageView: xibView.sliderImageView)
        }
    }
    
    @objc func cameraAction() {
        maskPortraitMatte.uIImageWriteToSavedPhotosAlbum(imageView: xibView.sliderImageView)
    }
}
