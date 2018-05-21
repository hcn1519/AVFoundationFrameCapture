//
//  ViewController.swift
//  AVFoundationCapture
//
//  Created by 홍창남 on 2018. 5. 13..
//  Copyright © 2018년 홍창남. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    let mediaPickerManager = MediaPickerManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        mediaPickerManager.mediaPickerDelegate = self
    }

    @IBAction func imageBtnTapped(_ sender: UIButton) {
        PHPhotoLibrary.checkPermission { isSuccess in
            DispatchQueue.main.async {
                if isSuccess {
                    self.present(self.mediaPickerManager.imagePicker, animated: true, completion: nil)
                }
            }
        }
    }
}

extension ViewController: MediaPickerDelegate {
    func didFinishPickingMedia(videoURL: URL) {
        let captureTime: [Double] = [12, 2, 3, 4]
        mediaPickerManager.generateThumbnailSync(url: videoURL, startOffsets: captureTime) { images in
            self.imageView.image = images.first!
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

