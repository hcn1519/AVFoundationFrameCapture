//
//  MediaPickerManager.swift
//  AVFoundationCapture
//
//  Created by 홍창남 on 2018. 5. 22..
//  Copyright © 2018년 홍창남. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import Photos

protocol MediaPickerDelegate {
    func didFinishPickingMedia(videoURL: URL)
}

class MediaPickerManager: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var mediaPickerDelegate: MediaPickerDelegate?

    lazy var imagePicker: UIImagePickerController = {

        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = ["public.movie"]
        return imagePicker
    }()
    
    // MARK: Create AVAssetImageGenerator

    func imageGenerator(asset: AVAsset) -> AVAssetImageGenerator {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 600, height: 600)

        imageGenerator.requestedTimeToleranceAfter = CMTimeMake(1, 600)
        imageGenerator.requestedTimeToleranceBefore = CMTimeMake(1, 600)
        return imageGenerator
    }

    // MARK: Get thumbnail images from video synchronously and return those as UIImage

    func generateThumbnailSync(url: URL, startOffsets: [Double],
                               completion: @escaping ([UIImage]) -> Void) {
        let asset = AVAsset(url: url)
        let imageGenerator = self.imageGenerator(asset: asset)

        let time: [CMTime] = startOffsets.compactMap {
            return CMTimeMakeWithSeconds(Float64($0), asset.duration.timescale)
        }

        let resultImages: [UIImage] = time.compactMap {
            if let image = try? imageGenerator.copyCGImage(at: $0, actualTime: nil) {
                return UIImage(cgImage: image)
            }
            return nil
        }

        completion(resultImages)
    }

    // MARK: Get thumbnail images from video asynchronously and return those as UIImage

    func generateThumnailAsync(url: URL, startOffsets: [Double],
                               completion: @escaping (UIImage) -> Void) {
        let asset = AVAsset(url: url)
        let imageGenerator = self.imageGenerator(asset: asset)

        let time: [NSValue] = startOffsets.compactMap {
            return NSValue(time: CMTimeMakeWithSeconds(Float64($0), asset.duration.timescale))
        }

        imageGenerator.generateCGImagesAsynchronously(forTimes: time) { _, image, _, _, _ in
            if let image = image {
                completion(UIImage(cgImage: image))
            }
        }
    }

    // MARK: Pick video from user's album

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let mediaType = info[UIImagePickerControllerMediaType] as? String else { return }

        if mediaType == kUTTypeMovie as String {
            if let videoURL = info[UIImagePickerControllerMediaURL] as? URL {
                
                mediaPickerDelegate?.didFinishPickingMedia(videoURL: videoURL)
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
