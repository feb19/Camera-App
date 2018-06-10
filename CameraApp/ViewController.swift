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
    var session = AVCaptureSession()
    var output = AVCapturePhotoOutput()
    let notification = NotificationCenter.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if session.isRunning {
            return
        }
        
        setup()
        preview()
        
        session.startRunning()
        notification.addObserver(self,
                                 selector: #selector(self.deviceOrientationDidChanged(_:)),
                                 name: NSNotification.Name.UIDeviceOrientationDidChange,
                                 object: nil)
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
        let setting = AVCapturePhotoSettings()
        setting.flashMode = .auto
        setting.isAutoStillImageStabilizationEnabled = true // 自動補正？
        setting.isHighResolutionPhotoEnabled = false
        output.capturePhoto(with: setting, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let photoData = photo.fileDataRepresentation() else {
            return
        }
        
        if let stillImage = UIImage(data: photoData) {
            UIImageWriteToSavedPhotosAlbum(stillImage, self, nil, nil)
        }
    }
}

