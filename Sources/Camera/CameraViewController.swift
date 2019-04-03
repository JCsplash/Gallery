//
//  CameraViewController.swift
//  FlairTime
//
//  Created by Jack Chen on 7/4/17.
//  Copyright © 2017 Flair Time LLC. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class CameraViewController: SwiftyCamViewController, SwiftyCamViewControllerDelegate {

    var flipCameraButton: UIButton!
    var flashButton: UIButton!
    var cancelButton: UIButton!
    var captureButton: SwiftyRecordButton!
    var delegate: CameraViewDelegate?
    
    private var tmpVideoURLs = NSSet() //to be cleaned up when deinit
    
    deinit {
        let filemgr = FileManager.default
        tmpVideoURLs.forEach { (url) in
            if let videoURL = url as? URL {
                do {
                    try filemgr.removeItem(at: videoURL)
                }
                catch let error {
                    print("Error removing temp video file \(videoURL) due to error \(error)")
                }
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraDelegate = self
        maximumVideoDuration = 15.0
        shouldUseDeviceOrientation = false
        allowAutoRotate = false
        audioEnabled = true
        allowBackgroundAudio = true
        addButtons()
    }
    
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        print("DID CAPTURE PHOTO!!!")
    }
    
    
    //MARK - VIDEO CAPTURE PROGRESSION
    override func buttonTouchesBegan() {
        super.buttonTouchesBegan()
        shouldChangeAudio = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
            guard self.shouldChangeAudio, !self.isVideoRecording else { return }
            print("Video Capture: Start animation since touch is longer than 150ms")
            self.captureButton.growButton(duration: 0.8)
            UIView.animate(withDuration: 0.25, animations: {
                self.flashButton.alpha = 0.0
                self.flipCameraButton.alpha = 0.0
                self.cancelButton.alpha = 0.0
            })
        })
    }
    
    override func buttonTouchesEnded() {
        super.buttonTouchesEnded()
        shouldChangeAudio = false
        guard self.isLongPressing == false && self.isVideoRecording == false else {return}
        print("Video Capture: End animation since touch is less than 250ms")
        self.captureButton.shrinkButton()
        self.showAllButtons()
    }
    
    override func buttonTouchesCancelled() {
        super.buttonTouchesCancelled()
        print("Button Touches Cancelled (Not Expected)")
//        shouldChangeAudio = false
//        guard self.isLongPressing == false && self.isVideoRecording == false else {return}
//        print("Video Capture: Cancel animation since touch is less than 250ms")
//        self.captureButton.shrinkButton()
//        self.showAllButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Video Capture: Video has begun recoring. Start timer and progress animation.")
        self.captureButton.animateCircle(duration: maximumVideoDuration)
        self.captureButton.startTimer()
        //print("\(Date().millisecondsSince1970 - startTime): didBeginRecordingVideo--1...")
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        //print("\(Date().millisecondsSince1970 - startTime): Did finish Recording")
        print("Video Capture: Finished recording. Reset capture button & timer.")
        captureButton.invalidateTimer()
        captureButton.shrinkButton()
        UIView.animate(withDuration: 0.5, delay: 0.3, animations: {
            self.captureButton.alpha = 0.0
        })
    }
    
    //MARK - CAMERA METHODS
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        print("DID CAPTURE VIDEO!!")
        tmpVideoURLs.adding(url) //to be cleaned up later
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        let focusView = UIImageView(image: Bundle.image("focus"))
        focusView.center = point
        focusView.alpha = 0.0
        view.addSubview(focusView)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }, completion: { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }, completion: { (success) in
                focusView.removeFromSuperview()
            })
        })
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
        //        print(zoom)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
        //        print(camera)
    }
    
    @objc private func cameraSwitchAction(_ sender: Any) {
        switchCamera()
    }
    
    @objc private func toggleFlashAction(_ sender: Any) {
        flashEnabled = !flashEnabled
        
        if flashEnabled == true {
            flashButton.setImage(Bundle.image("flash_fill"), for: UIControlState())
        } else {
            flashButton.setImage(Bundle.image("flash_outline"), for: UIControlState())
        }
    }
    
    func cancelButtonPressed(_ sender: Any) {
        print("CANCEL BUTTON PRESSED")
    }

    private func addButtons() {
        let safeAreaTopSpace = CommonUtils.safeAreaInsets.top * 0.8
        let safeAreaBottomSpace = CommonUtils.safeAreaInsets.bottom * 0.6
        
        captureButton = SwiftyRecordButton(frame: CGRect(x: view.frame.midX - 37.5, y: view.frame.height - 110.0 - 25.0 - safeAreaBottomSpace, width: 75.0, height: 75.0))
        self.view.addSubview(captureButton)
        captureButton.delegate = self
        
        let flashView = UIView(frame: CGRect(x: view.frame.width / 2 - 25.0, y: 0.0 + safeAreaTopSpace, width: 50.0, height: 50.0))
        flashButton = UIButton(frame: CGRect(x: 25.0 - 9.0, y: 25.0 - 15.0 , width: 18.0, height: 30.0))
        flashButton.setImage(Bundle.image("flash_outline"), for: UIControlState())

        flashButton.isUserInteractionEnabled = false
        flashView.addSubview(flashButton)
        
        let flashTap = UITapGestureRecognizer(target: self, action: #selector(toggleFlashAction(_:)))
        flashView.addGestureRecognizer(flashTap)
        flashView.isUserInteractionEnabled = true
        view.addSubview(flashView)
        
        let flipCameraView = UIView(frame: CGRect(x: view.frame.width - 50.0, y: 0.0 + safeAreaTopSpace, width: 50.0, height: 50.0))
        flipCameraButton = UIButton(frame: CGRect(x: 25.0 - 15.0, y: 25.0 - 11.5, width: 30.0, height: 23.0))
        flipCameraButton.setImage(Bundle.image("camera_flip"), for: UIControlState())
        flipCameraButton.isUserInteractionEnabled = false
        flipCameraView.addSubview(flipCameraButton)
        
        let flipTap = UITapGestureRecognizer(target: self, action: #selector(cameraSwitchAction(_:)))
        flipCameraView.addGestureRecognizer(flipTap)
        flipCameraView.isUserInteractionEnabled = true
        view.addSubview(flipCameraView)
        
        let cancelView = UIView(frame: CGRect(x: 0.0, y: 0.0 + safeAreaTopSpace, width: 50.0, height: 50.0))
        cancelButton = UIButton(frame: CGRect(x: 25.0 - 10.0 , y: 25.0 - 10.0 , width: 20.0, height: 20.0))
        cancelButton.isUserInteractionEnabled = false
        cancelButton.setImage(Bundle.image("cancel"), for: UIControlState())
        cancelView.addSubview(cancelButton)
        
        let cancelTap = UITapGestureRecognizer(target: self, action: #selector(cancelButtonPressed(_:)))
        cancelView.addGestureRecognizer(cancelTap)
        cancelView.isUserInteractionEnabled = true
        view.addSubview(cancelView)
    }
    
    private func showAllButtons() {
        UIView.animate(withDuration: 0.25, animations: {
            self.flashButton.alpha = 1.0
            self.flipCameraButton.alpha = 1.0
            self.cancelButton.alpha = 1.0
            self.captureButton.alpha = 1.0
        })
    }
}
