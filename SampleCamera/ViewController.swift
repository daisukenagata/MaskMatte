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
    // デバイスからの入力と出力を管理するオブジェクトの作成
    var captureSession = AVCaptureSession()
    // カメラデバイスそのものを管理するオブジェクトの作成
    // メインカメラの管理オブジェクトの作成
    var mainCamera: AVCaptureDevice?
    // インカメの管理オブジェクトの作成
    var innerCamera: AVCaptureDevice?
    // 現在使用しているカメラデバイスの管理オブジェクトの作成
    var currentDevice: AVCaptureDevice?
    // キャプチャーの出力データを受け付けるオブジェクト
    var photoOutput : AVCapturePhotoOutput?
    // プレビュー表示用のレイヤ
    var cameraPreviewLayer : AVCaptureVideoPreviewLayer?
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
                                                                                  mediaType: .video, position: .unspecified)
    
    var imageView = UIImageView()
    // シャッターボタン
    @IBOutlet weak var cameraButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        self.setupInputOutput()
        setupPreviewLayer()
        captureSession.startRunning()
        styleCaptureButton()
        imageView.frame = view.frame
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // シャッターボタンが押された時のアクション
    @IBAction func cameraButton_TouchUpInside(_ sender: Any) {
        
        var settings = AVCapturePhotoSettings()
        settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        settings.flashMode = .auto
        settings.isHighResolutionPhotoEnabled = true
        
        settings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: settings.__availablePreviewPhotoPixelFormatTypes.first!]
        
        settings.isDepthDataDeliveryEnabled = true
        settings.isPortraitEffectsMatteDeliveryEnabled = true
        if !(self.photoOutput?.enabledSemanticSegmentationMatteTypes.isEmpty)! {
            settings.enabledSemanticSegmentationMatteTypes = self.photoOutput!.enabledSemanticSegmentationMatteTypes
        }
        
        
        settings.photoQualityPrioritization = self.photoQualityPrioritizationMode
        
        //AVCapturePhotoCaptureDelegate
        // 撮影された画像をdelegateメソッドで処理maskPortraitMatte
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

}
 let maskPortraitMatte = MaskFilterBuiltinsMatte()
//MARK: AVCapturePhotoCaptureDelegateデリゲートメソッド
extension ViewController: AVCapturePhotoCaptureDelegate{
    // 撮影した画像データが生成されたときに呼び出されるデリゲートメソッド
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        var uiImage = UIImage()
        if let imageData = photo.fileDataRepresentation() {
            // Data型をUIImageオブジェクトに変換
            uiImage = UIImage(data: imageData)!
//
            // 写真ライブラリに画像を保存
            for semanticSegmentationType in output.enabledSemanticSegmentationMatteTypes {
                print(maskPortraitMatte.maskFilterBuiltins(photo, ssmType:semanticSegmentationType,  image: uiImage) ?? UIImage())
                imageView.image = maskPortraitMatte.maskFilterBuiltins(photo, ssmType:semanticSegmentationType,  image: uiImage) ?? UIImage()
                self.view.addSubview(imageView)
                UIImageWriteToSavedPhotosAlbum( maskPortraitMatte.maskFilterBuiltins(photo, ssmType:semanticSegmentationType,  image: uiImage) ?? UIImage(), nil,nil,nil)
            }
        }
    }
}

//MARK: カメラ設定メソッド
extension ViewController{
    // カメラの画質の設定
    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }

//    // デバイスの設定
//    func setupDevice() {
//        // カメラデバイスのプロパティ設定
//        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInDualCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
//
//
//        // プロパティの条件を満たしたカメラデバイスの取得
//        let devices = deviceDiscoverySession.devices
//
//        for device in devices {
//            if device.position == AVCaptureDevice.Position.back {
//                mainCamera = device
//            } else if device.position == AVCaptureDevice.Position.front {
//                innerCamera = device
//            }
//        }
//        // 起動時のカメラを設定
//        currentDevice = innerCamera
//    }

    // 入出力データの設定
    func setupInputOutput() {
        // 出力データを受け取るオブジェクトの作成
        photoOutput = AVCapturePhotoOutput()
        guard let photoOutput = photoOutput else { return }
        do {
            captureSession.beginConfiguration()

            captureSession.sessionPreset = .photo
            
            // カメラデバイスのプロパティ設定
                   let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInDualCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
                   
                   
                   // プロパティの条件を満たしたカメラデバイスの取得
                   let devices = deviceDiscoverySession.devices

                   for device in devices {
                       if device.position == AVCaptureDevice.Position.back {
                            currentDevice = self.cameraWithPosition(.front)!
                       } else if device.position == AVCaptureDevice.Position.front {
                           currentDevice = self.cameraWithPosition(.back)!
                       }
                   }
         

            guard let videoDevice = currentDevice else { return }
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) { captureSession.addInput(videoDeviceInput) }
            
            currentDevice = AVCaptureDevice.default(for: .audio)
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print(error)
        }
        
        if captureSession.canAddOutput(photoOutput) {
            // 指定した入力をセッションに追加
            captureSession.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported
            photoOutput.enabledSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
            photoOutput.maxPhotoQualityPrioritization = .quality
            captureSession.commitConfiguration()
        }
        var newVideoDevice: AVCaptureDevice? = nil
               let devices = self.videoDeviceDiscoverySession.devices
               if let device = devices.first(where: { $0.position == .front && $0.deviceType == .builtInTrueDepthCamera }) {
                    newVideoDevice  = device
               } else if let device = devices.first(where: { $0.position == .front }) {
                    newVideoDevice = device
               }
               if let videoDevice = newVideoDevice {
                   do {
                       let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                       
                       self.captureSession.beginConfiguration()
                       self.captureSession.removeInput(self.videoDeviceInput)
                       
                       if self.captureSession.canAddInput(videoDeviceInput) {
                           self.captureSession.addInput(videoDeviceInput)
                           self.videoDeviceInput = videoDeviceInput
                       }
                       photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
                       photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
                       photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported
                       photoOutput.enabledSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
                       photoOutput.maxPhotoQualityPrioritization = .quality
                       photoQualityPrioritizationMode = .balanced
                       captureSession.commitConfiguration()
                   } catch {
                       print("Error occurred while creating video device input: \(error)")
                       
                   }
               }
    }
    
    // カメラのプレビューを表示するレイヤの設定
    func setupPreviewLayer() {
        // 指定したAVCaptureSessionでプレビューレイヤを初期化
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        // プレビューレイヤが、カメラのキャプチャーを縦横比を維持した状態で、表示するように設定
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        // プレビューレイヤの表示の向きを設定
        self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        
        self.cameraPreviewLayer?.frame = view.frame
        self.view.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)
    }
    
    // ボタンのスタイルを設定
    func styleCaptureButton() {
        cameraButton.layer.borderColor = UIColor.white.cgColor
        cameraButton.layer.borderWidth = 5
        cameraButton.clipsToBounds = true
        cameraButton.layer.cornerRadius = min(cameraButton.frame.width, cameraButton.frame.height) / 2
    }
    
    func cameraWithPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceDescoverySession =

            AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                  mediaType: AVMediaType.video,
                                                  position: AVCaptureDevice.Position.unspecified)

        for device in deviceDescoverySession.devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
}

import CoreImage.CIFilterBuiltins

@available(iOS 13.0, *)
class MaskFilterBuiltinsMatte: NSCoder {
    lazy var context = CIContext()
    func maskFilterBuiltins(_ photo: AVCapturePhoto,ssmType: AVSemanticSegmentationMatte.MatteType, image: UIImage) -> UIImage? {
        guard let segmentationMatte = photo.semanticSegmentationMatte(for: ssmType) else { return nil}
        var imageOption: CIImageOption!
        switch ssmType {
        case .hair:
            imageOption = .auxiliarySemanticSegmentationHairMatte
        case .skin:
            imageOption = .auxiliarySemanticSegmentationSkinMatte
        case .teeth:
            imageOption = .auxiliarySemanticSegmentationTeethMatte
        default:
            print("This semantic segmentation type is not supported!")
            break
        }

            let ciImage = CIImage(cvImageBuffer: segmentationMatte.mattingImage, options: [imageOption: true])
        
            let base = CIImage(image: image)
            let maxcomp = CIFilter.maximumComponent()
            maxcomp.inputImage = base
            var makeup = maxcomp.outputImage
            let gamma = CIFilter.gammaAdjust()
            gamma.inputImage = makeup
            gamma.power = 0.5
            makeup = gamma.outputImage

            var matte = CIImage(cvImageBuffer: segmentationMatte.mattingImage, options: [.auxiliarySemanticSegmentationSkinMatte: true])

            guard let baseImage = base else { return nil}
            let scale = CGAffineTransform(scaleX: baseImage.extent.size.width / matte.extent.size.width,
                                          y: baseImage.extent.size.height / matte.extent.size.height)
            matte = matte.transformed( by: scale )

            let blend = CIFilter.blendWithMask()
            blend.backgroundImage = base
            blend.inputImage = makeup
            blend.maskImage = matte

            let result = blend.outputImage

            guard let outputImage = result else { return nil}
        
        // Get the HEIF representation of this image.
        guard let linearColorSpace = CGColorSpace(name: CGColorSpace.linearSRGB),
            let imageData = context.heifRepresentation(of: outputImage,
                                                       format: .RGBA8,
                                                       colorSpace: linearColorSpace,
                                                       options: [.depthImage: ciImage]) else { return nil}
        
        
        return UIImage(data: imageData)
    }
}
