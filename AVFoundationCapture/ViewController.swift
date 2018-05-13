//
//  ViewController.swift
//  AVFoundationCapture
//
//  Created by 홍창남 on 2018. 5. 13..
//  Copyright © 2018년 홍창남. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import Photos


class ImagePickerManager: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var viewController: ViewController?

    func generateThumnail(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 400, height: 500)

        let time = getTime(asset: asset, startOffset: 33.423)

        if let image = try? imageGenerator.copyCGImage(at: time!, actualTime: nil) {
            return UIImage(cgImage: image)
        }
        return nil
    }

    func generateThumnailAsync(url: URL, completion: @escaping (UIImage) -> Void) {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 400, height: 500)

        imageGenerator.requestedTimeToleranceAfter = CMTimeMake(1, 600)
        imageGenerator.requestedTimeToleranceBefore = CMTimeMake(1, 600)

        let time = getTime(asset: asset, startOffset: 35.223) as! NSValue

        imageGenerator.generateCGImagesAsynchronously(forTimes: [time]) { _, image, _, _, _ in
            if let image = image {
                completion(UIImage(cgImage: image))
            }
        }
    }

    func getTime(asset: AVAsset, startOffset: Double) -> CMTime? {
        let duration = asset.duration
        let scale: Int64 = Int64(duration.timescale)

        let totalRunningTime = duration.value / scale

        let offset = Int64(Double(duration.timescale) * startOffset)

        print(offset)
        print(duration.timescale)

//        return CMTimeMake(20 * 1000000, 1000000)
        return CMTimeMakeWithSeconds(Float64(startOffset), duration.timescale)
//        return startOffset <= Double(totalRunningTime) && startOffset >= 0 ? CMTimeMake(offset, duration.timescale) : nil
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let mediaType = info[UIImagePickerControllerMediaType] as? String else { return }

        if mediaType == kUTTypeMovie as String {
            if let tempVideo = info[UIImagePickerControllerMediaURL] as? URL {
                self.generateThumnailAsync(url: tempVideo) { image in
                    self.viewController?.pickedImage = image
                }
//                if let thumbnail = self.generateThumnail(url: tempVideo) {
//                    viewController?.pickedImage = thumbnail
//                }
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    var imageManager = ImagePickerManager()
    let imagePicker = UIImagePickerController()

    var pickedImage: UIImage? {
        didSet {
            self.imageView.image = pickedImage
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        imageManager.viewController = self
        imagePicker.delegate = imageManager
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = ["public.movie"]
    }
    @IBAction func imageBtnTapped(_ sender: UIButton) {
        PHPhotoLibrary.checkPermission { isSuccess in
            DispatchQueue.main.async {
                if isSuccess {
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
            }
        }
    }
}

extension PHPhotoLibrary {
    static func checkPermission(completion: @escaping (Bool) -> Void) {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            print("Access is granted by user")
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                print("status is \(newStatus)")
                if newStatus ==  PHAuthorizationStatus.authorized {
                    /* do stuff here */
                    print("success")
                    completion(true)
                }
            })
            print("It is not determined until now")
        case .restricted:
            print("User do not have access to photo album.")
            completion(false)
        case .denied:
            print("User has denied the permission.")
            completion(false)
        }
    }
}

