//
//  ViewController.swift
//  SampleCamera
//
//  Created by 永田大祐 on 2019/11/03.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

@available(iOS 13.0, *)
class ViewController: UIViewController {
    private enum DepthDataDeliveryMode {
        case on
        case off
    }
    private enum PortraitEffectsMatteDeliveryMode {
        case on
        case off
    }
    private var depthDataDeliveryMode: DepthDataDeliveryMode = .off
    private var portraitEffectsMatteDeliveryMode: PortraitEffectsMatteDeliveryMode = .off
    
    private var photoQualityPrioritizationMode: AVCapturePhotoOutput.QualityPrioritization = .balanced
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    let maskPortraitMatte = MaskFilterBuiltinsMatte()
    
 
    // シャッターボタン
    @IBOutlet weak var cameraButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        self.setupInputOutput()
        setupPreviewLayer()
         maskPortraitMatte.captureSession.startRunning()
        styleCaptureButton()
    }

    // シャッターボタンが押された時のアクション
    @IBAction func cameraButton_TouchUpInside(_ sender: Any) {
        maskPortraitMatte.cameraAction()
    }

}

//MARK: カメラ設定メソッド
extension ViewController{
    // カメラの画質の設定
    func setupCaptureSession() {
        maskPortraitMatte.captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }

    // 入出力データの設定
    func setupInputOutput() {
        maskPortraitMatte.setupInputOutput()
    }

    // カメラのプレビューを表示するレイヤの設定
    func setupPreviewLayer() {
        maskPortraitMatte.setupPreviewLayer(view)
    }

    // ボタンのスタイルを設定
    func styleCaptureButton() {
        cameraButton.layer.borderColor = UIColor.white.cgColor
        cameraButton.layer.borderWidth = 5
        cameraButton.clipsToBounds = true
        cameraButton.layer.cornerRadius = min(cameraButton.frame.width, cameraButton.frame.height) / 2
    }
}
