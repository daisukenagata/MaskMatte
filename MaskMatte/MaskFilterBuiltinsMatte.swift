//
//  MaskFilterBuiltinsMatte.swift
//  MaskMatte
//
//  Created by 永田大祐 on 2019/11/05.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage.CIFilterBuiltins

@available(iOS 13.0, *)
class MaskFilterBuiltinsMatte: NSObject {

    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    var call                    = { (_ image: UIImage?) -> Void in }
    var captureSession          = AVCaptureSession()
    var based                   : CIImage?
    var photos                  : AVCapturePhoto?
    var mainCamera              : AVCaptureDevice?
    var innerCamera             : AVCaptureDevice?
    var currentDevice           : AVCaptureDevice?
    var photoOutput             : AVCapturePhotoOutput?
    var cameraPreviewLayer      : AVCaptureVideoPreviewLayer?
    var semanticSegmentationType: AVSemanticSegmentationMatte.MatteType?

    lazy var context = CIContext()

    private var photoQualityPrioritizationMode: AVCapturePhotoOutput.QualityPrioritization = .balanced
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
                                                                                  mediaType: .video, position: .unspecified)

    func setMaskFilter(view: UIView) {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        setupInputOutput()
        setupPreviewLayer(view)
        captureSession.startRunning()
    }

    func setupPreviewLayer(_ view: UIView) {
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        self.cameraPreviewLayer?.frame = view.frame
        view.layer.insertSublayer(self.cameraPreviewLayer ?? AVCaptureVideoPreviewLayer(), at: 0)
    }

    func cameraAction(_ callBack: @escaping (_ image: UIImage?) -> Void){
        var settings = AVCapturePhotoSettings()
        settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        settings.flashMode = .auto
        settings.isHighResolutionPhotoEnabled = true
        settings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: settings.__availablePreviewPhotoPixelFormatTypes.first!]
        settings.isDepthDataDeliveryEnabled = true
        settings.isPortraitEffectsMatteDeliveryEnabled = true
        if !(self.photoOutput?.enabledSemanticSegmentationMatteTypes.isEmpty)! {
            settings.enabledSemanticSegmentationMatteTypes = self.photoOutput?.enabledSemanticSegmentationMatteTypes ?? [AVSemanticSegmentationMatte.MatteType]()
        }
        
        settings.photoQualityPrioritization = self.photoQualityPrioritizationMode
        photoOutput?.capturePhoto(with: settings, delegate: self)

        call = callBack
    }

    func setupInputOutput() {
        photoOutput = AVCapturePhotoOutput()
        guard let photoOutput = photoOutput else { return }
        do {
            captureSession.beginConfiguration()
            captureSession.sessionPreset = .photo

            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInDualCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)

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

    func maskFilterBuiltins(_ bind: @escaping (_ image: UIImage?) -> Void ,photo: AVCapturePhoto ,ssmType: AVSemanticSegmentationMatte.MatteType, image: UIImage) {

        guard var segmentationMatte = photo.semanticSegmentationMatte(for: ssmType),
            let base = CIImage(image: image.updateImageOrientionUpSide()) else { return }
        photos = photo
        based = base

        if let orientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
            let exifOrientation = CGImagePropertyOrientation(rawValue: orientation) {
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

        gamma.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputRVector")
        gamma.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        gamma.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputBVector")
        gamma.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        makeup = gamma.outputImage

        var matte = CIImage(cvImageBuffer: segmentationMatte.mattingImage, options: [imageOption : true])

        let scale = CGAffineTransform(scaleX: base.extent.size.width / matte.extent.size.width,
                                      y: base.extent.size.height / matte.extent.size.height)
        matte = matte.transformed( by: scale )

        let blend = CIFilter.blendWithMask()
        blend.backgroundImage = base
        blend.inputImage = makeup
        blend.maskImage = matte
        let result = blend.outputImage
        guard let outputImage = result else { return }
        guard let perceptualColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return }

        let ciImage = CIImage( cvImageBuffer: segmentationMatte.mattingImage,
                               options: [imageOption: true,
                                         .colorSpace: perceptualColorSpace])

        guard let linearColorSpace = CGColorSpace(name: CGColorSpace.linearSRGB),
            let imagedata = context.pngRepresentation(of: outputImage,
                                                  format: .RGBA8,
                                                  colorSpace: linearColorSpace,
                                                  options: [.semanticSegmentationSkinMatteImage : ciImage,
                                                            .semanticSegmentationHairMatteImage : ciImage,
                                                            .semanticSegmentationTeethMatteImage: ciImage,]) else { return }
        
        bind(UIImage(data: imagedata))
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

    func maskFilterBuiltinsChanges(value : Float,
                             value2: Float,
                             value3: Float,
                             value4: Float,
                             photo: AVCapturePhoto?,
                             ssmType: AVSemanticSegmentationMatte.MatteType?,
                             imageView: UIImageView) {

        guard let ssmType = ssmType else { return }
        guard var segmentationMatte = photo?.semanticSegmentationMatte(for: ssmType) else { return }
        let base = based

        if let orientation = photo?.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
            let exifOrientation = CGImagePropertyOrientation(rawValue: orientation) {

            segmentationMatte = segmentationMatte.applyingExifOrientation(exifOrientation)
        }

        let maxcomp1 = CIFilter.maximumComponent()
        maxcomp1.inputImage = base
        var makeup1 = maxcomp1.outputImage
        let gamma1 = CIFilter.gammaAdjust()
        gamma1.inputImage = base
        gamma1.power = value
        makeup1 = gamma1.outputImage

        let maxcomp = CIFilter.maximumComponent()
        maxcomp.inputImage = makeup1
        var makeup = maxcomp.outputImage
        let gamma = CIFilter.colorMatrix()
        gamma.inputImage = makeup1

        gamma.setValue(CIVector(x: 0, y: CGFloat(value2), z: 0, w: 0), forKey: "inputRVector")
        gamma.setValue(CIVector(x: 0, y: CGFloat(value3), z: 0, w: 0), forKey: "inputGVector")
        gamma.setValue(CIVector(x: 0, y: CGFloat(value4), z: 0, w: 0), forKey: "inputBVector")
        gamma.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        makeup = gamma.outputImage

        var matte = CIImage(cvImageBuffer: segmentationMatte.mattingImage, options: [.auxiliarySemanticSegmentationHairMatte : true])
        let scale = CGAffineTransform(scaleX: based?.extent.size.width ?? 0.0 / matte.extent.size.width,
                                      y: based?.extent.size.height ?? 0.0 / matte.extent.size.height)
        matte = matte.transformed( by: scale )
        
        let blend = CIFilter.blendWithMask()
        blend.backgroundImage = base
        blend.inputImage = makeup
        blend.maskImage = matte
        let result = blend.outputImage

        guard let outputImage = result else { return }
        guard let perceptualColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return }

        let ciImage = CIImage( cvImageBuffer: segmentationMatte.mattingImage,
                               options: [.auxiliarySemanticSegmentationHairMatte: true,
                                         .colorSpace: perceptualColorSpace])

        guard let linearColorSpace = CGColorSpace(name: CGColorSpace.linearSRGB),
            let imagedata = context.pngRepresentation(of: outputImage,
                                                      format: .RGBA8,
                                                      colorSpace: linearColorSpace,
                                                      options: [ .semanticSegmentationHairMatteImage : ciImage,]) else { return }

        imageView.image = UIImage(data: imagedata)
    }
}

//MARK: AVCapturePhotoCaptureDelegate
extension MaskFilterBuiltinsMatte: AVCapturePhotoCaptureDelegate{
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        var uiImage: UIImage?
        if let imageData = photo.fileDataRepresentation() {

            uiImage = UIImage(data: imageData)

            for semanticSegmentationTypes in output.enabledSemanticSegmentationMatteTypes {
                if semanticSegmentationTypes == .hair {
                    semanticSegmentationType = semanticSegmentationTypes
                    maskFilterBuiltins(callBack(image:), photo: photo, ssmType: semanticSegmentationType!, image: uiImage ?? UIImage())
                }
            }
        }
    }
    func callBack(image: UIImage?) { call(image) }
}

// Image extension
extension UIImage {
    func updateImageOrientionUpSide() -> UIImage {
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
        return UIImage()
    }
}
