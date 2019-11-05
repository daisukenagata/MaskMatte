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

    let maskPortraitMatte = MaskFilterBuiltinsMatte()

    var callBack = { () -> Void in }

    let xibView = SliiderObjects()

    static func identifier() -> String { return String(describing: ViewController.self) }

    static func viewController() -> ViewController {

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateInitialViewController() as! ViewController
        return vc
    }

    init() {
        super.init(nibName: "Main", bundle: Bundle.main)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCaptureSession()
        setupInputOutput()
        setupPreviewLayer()
        maskPortraitMatte.captureSession.startRunning()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

        let bt = UIButton()
        bt.frame = CGRect(x: (self.tabBarController?.tabBar.frame.width ?? 0.0) / 2 - 25,
                          y: (self.tabBarController?.tabBar.frame.height ?? 0.0) / 2 - 25, width: 50, height: 50)
        bt.backgroundColor = .red
        self.tabBarController?.tabBar.addSubview(bt)
        bt.layer.cornerRadius = bt.frame.height/2
        bt.addTarget(self, action: #selector(btAction), for: .touchUpInside)
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
            maskPortraitMatte.maskFilterBuiltinsChanges(value : xibView.sliderInputRVector.value,
                                                        value2: xibView.sliderInputGVector.value,
                                                        value3: xibView.sliderInputBVector.value,
                                                        value4: xibView.sliderInputAVector.value,
                                                        photo: maskPortraitMatte.photos,
                                                        ssmType: maskPortraitMatte.semanticSegmentationType,
                                                        imageView: xibView.sliderImageView)
        }
    }
}

extension ViewController{

    func setupCaptureSession() { maskPortraitMatte.captureSession.sessionPreset = AVCaptureSession.Preset.photo }

    func setupInputOutput() { maskPortraitMatte.setupInputOutput() }

    func setupPreviewLayer() {
        let d = UIView(frame: CGRect(x: 0, y: 44, width: self.view.frame.width, height: self.view.frame.height - 188))
        view.addSubview(d)
        maskPortraitMatte.setupPreviewLayer(d)
    }
}
