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
class MaskFilterBuiltinsMatte: NSCoder {

    lazy var context = CIContext()

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

