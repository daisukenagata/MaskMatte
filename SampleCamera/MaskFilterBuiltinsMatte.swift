//
//  MaskFilterBuiltinsMatte.swift
//  SampleCamera
//
//  Created by 永田大祐 on 2019/11/05.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage.CIFilterBuiltins

@available(iOS 13.0, *)
class MaskFilterBuiltinsMatte: NSObject {

    lazy var context = CIContext()
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
    
    func setupPreviewLayer(_ view: UIView) {
        // 指定したAVCaptureSessionでプレビューレイヤを初期化
              self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
              // プレビューレイヤが、カメラのキャプチャーを縦横比を維持した状態で、表示するように設定
              self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
              // プレビューレイヤの表示の向きを設定
              self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
              
              self.cameraPreviewLayer?.frame = view.frame
              view.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)
    }
    func cameraAction(){
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

    func maskFilterBuiltins(_ photo: AVCapturePhoto,ssmType: AVSemanticSegmentationMatte.MatteType, image: UIImage) -> UIImage? {

        guard var segmentationMatte = photo.semanticSegmentationMatte(for: ssmType) else { return nil}
        let base = CIImage(image: image.updateImageOrientionUpSide()!)
        
        // Retrieve the photo orientation and apply it to the matte image.
        if let orientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
            let exifOrientation = CGImagePropertyOrientation(rawValue: orientation) {
            // Apply the Exif orientation to the matte image.
            segmentationMatte = segmentationMatte.applyingExifOrientation(exifOrientation)
        }
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
        let maxcomp1 = CIFilter.maximumComponent()
        maxcomp1.inputImage = base
        var makeup1 = maxcomp1.outputImage
        let gamma1 = CIFilter.gammaAdjust()
        gamma1.inputImage = base
        gamma1.power = 0.65
        makeup1 = gamma1.outputImage
        
        let maxcomp = CIFilter.maximumComponent()
        maxcomp.inputImage = makeup1
        var makeup = maxcomp.outputImage
        let gamma = CIFilter.colorMatrix()
        gamma.inputImage = makeup1
        // RGBの変換値を作成.
        gamma.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        gamma.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        gamma.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        gamma.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        gamma.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
        makeup = gamma.outputImage

        var matte = CIImage(cvImageBuffer: segmentationMatte.mattingImage, options: [imageOption : true])

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

        
        
        
        guard let perceptualColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil}
        // Create a new CIImage from the matte's underlying CVPixelBuffer.
        let ciImage = CIImage( cvImageBuffer: segmentationMatte.mattingImage,
                               options: [imageOption: true,
                                         .colorSpace: perceptualColorSpace])
    
        // Get the HEIF representation of this image.
        guard let linearColorSpace = CGColorSpace(name: CGColorSpace.linearSRGB),
            let imageData = context.pngRepresentation(of: outputImage,
                                                       format: .RGBA8,
                                                       colorSpace: linearColorSpace,
                                                       options: [.semanticSegmentationSkinMatteImage : ciImage,
                                                                 .semanticSegmentationHairMatteImage : ciImage,
                                                                 .semanticSegmentationTeethMatteImage: ciImage,]) else { return nil }
        

        return UIImage(data: imageData)
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

//MARK: AVCapturePhotoCaptureDelegateデリゲートメソッド
extension MaskFilterBuiltinsMatte: AVCapturePhotoCaptureDelegate{
    // 撮影した画像データが生成されたときに呼び出されるデリゲートメソッド
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        var uiImage = UIImage()
        if let imageData = photo.fileDataRepresentation() {
            // Data型をUIImageオブジェクトに変換
            uiImage = UIImage(data: imageData)!
            // 写真ライブラリに画像を保存
            for semanticSegmentationType in output.enabledSemanticSegmentationMatteTypes {
                UIImageWriteToSavedPhotosAlbum( maskFilterBuiltins(photo, ssmType:semanticSegmentationType,  image: uiImage) ?? UIImage(), nil,nil,nil)
            }
        }
    }
}

// Image extension
extension UIImage {
    
    func updateImageOrientionUpSide() -> UIImage? {
        if self.imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        if let normalizedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return normalizedImage
        }
        UIGraphicsEndImageContext()
        return nil
    }
}
