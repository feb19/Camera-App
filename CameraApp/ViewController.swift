//
//  ViewController.swift
//  CameraApp
//
//  Created by TakahashiNobuhiro on 2018/06/10.
//  Copyright © 2018 feb19. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    var session = AVCaptureSession()
    var output = AVCapturePhotoOutput()
    let notification = NotificationCenter.default
    var authorizeStatus: AuthorizeStatus = .authorized
    var inOutStatus: InputOutputStatus = .ready
    var shareImage: UIImage?
    
    enum AuthorizeStatus {
        case authorized
        case notAuthorized
        case failed
    }
    enum InputOutputStatus {
        case ready
        case notReady
        case failed
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        shutterButton.isEnabled = false
        shareButton.isEnabled = false
        
        guard !session.isRunning else {
            return
        }
        auth()
        setup()
        
        if (authorizeStatus == .authorized) && (inOutStatus == .ready) {
            preview()
            session.startRunning()
            shutterButton.isEnabled = true
        } else {
            showAlert(appName: "カメラ")
        }
        notification.addObserver(self,
                                 selector: #selector(self.deviceOrientationDidChanged(_:)),
                                 name: NSNotification.Name.UIDeviceOrientationDidChange,
                                 object: nil)
    }
    
    func auth() {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { [unowned self] authorized in
                print("This print is first time. \(authorized.description)")
                if authorized {
                    self.authorizeStatus = .authorized
                } else {
                    self.authorizeStatus = .notAuthorized
                }
            })
        case .restricted, .denied:
            authorizeStatus = .notAuthorized
        case .authorized:
            authorizeStatus = .authorized
        }
    }
    
    func showAlert(appName :String) {
        let alert = UIAlertController(title: "\(appName)のプライバシー設定",
            message: "設定→プライバシー→\(appName)の利用を許可してください。",
            preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        alert.addAction(UIAlertAction(title: "設定を開く", style: UIAlertActionStyle.default, handler: { (action) in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func deviceOrientationDidChanged(_ notification: Notification) {
        if let photoOutputConnection = output.connection(with: AVMediaType.video) {
            switch UIDevice.current.orientation {
            case .portrait:
                photoOutputConnection.videoOrientation = .portrait
            case .portraitUpsideDown:
                photoOutputConnection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                photoOutputConnection.videoOrientation = .landscapeLeft
            case .landscapeRight:
                photoOutputConnection.videoOrientation = .landscapeRight
            default:
                break
            }
        }
    }
    
    func setup() {
        session.sessionPreset = AVCaptureSession.Preset.photo
        do {
            let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                                 for: AVMediaType.video,
                                                 position: AVCaptureDevice.Position.back)
            let input = try AVCaptureDeviceInput(device: device!)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                print("It could not add an input to session.")
                return
            }
        } catch let error as NSError {
            print("No camera. \(error)")
            return
        }
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            print("It could not add an output to session.")
            return
        }
    }
    
    func preview() {
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.masksToBounds = true
        preview.videoGravity = AVLayerVideoGravity.resizeAspect
        previewView.layer.addSublayer(preview)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func shotButtonWasTapped(_ sender: Any) {
        if (authorizeStatus == .authorized) && (inOutStatus == .ready) {
            let setting = AVCapturePhotoSettings()
            setting.flashMode = .auto
            setting.isAutoStillImageStabilizationEnabled = true // 自動補正？
            setting.isHighResolutionPhotoEnabled = false
            output.capturePhoto(with: setting, delegate: self)
        } else {
            showAlert(appName: "カメラ")
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let photoData = photo.fileDataRepresentation() else {
            return
        }
        
        if let stillImage = UIImage(data: photoData) {
            UIImageWriteToSavedPhotosAlbum(stillImage, self, nil, nil)
            shareImage = stillImage
            shareButton.isEnabled = true
        }
    }
    
    @IBAction func actionButtonWasTapped(_ sender: UIBarButtonItem) {
        guard let shareImage = shareImage else {
            return
        }
        let shareText = "これをシェアします"
        let shareUrl = ""
        let activities = [shareText, shareUrl, shareImage] as [Any]
        let vc = UIActivityViewController(activityItems: activities, applicationActivities: nil)
        self.present(vc, animated: true, completion: nil)
    }
}

