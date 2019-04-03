/*Copyright (c) 2016, Andrew Walz.

Redistribution and use in source and binary forms, with or without modification,are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit
import AVFoundation
import PromiseKit

// MARK: View Controller Declaration

/// A UIViewController Camera View Subclass

open class SwiftyCamViewController: UIViewController {

	// MARK: Enumeration Declaration

	/// Enumeration for Camera Selection

	public enum CameraSelection {

		/// Camera on the back of the device
		case rear

		/// Camera on the front of the device
		case front
	}

	/// Enumeration for video quality of the capture session. Corresponds to a AVCaptureSessionPreset


	public enum VideoQuality {

		/// AVCaptureSessionPresetHigh
		case high

		/// AVCaptureSessionPresetMedium
		case medium

		/// AVCaptureSessionPresetLow
		case low

		/// AVCaptureSessionPreset352x288
		case resolution352x288

		/// AVCaptureSessionPreset640x480
		case resolution640x480

		/// AVCaptureSessionPreset1280x720
		case resolution1280x720

		/// AVCaptureSessionPreset1920x1080
		case resolution1920x1080

		/// AVCaptureSessionPreset3840x2160
		case resolution3840x2160

		/// AVCaptureSessionPresetiFrame960x540
		case iframe960x540

		/// AVCaptureSessionPresetiFrame1280x720
		case iframe1280x720
	}

	/**

	Result from the AVCaptureSession Setup

	- success: success
	- notAuthorized: User denied access to Camera of Microphone
	- configurationFailed: Unknown error
	*/

	fileprivate enum SessionSetupResult {
		case success
		case notAuthorized
		case configurationFailed
	}

	// MARK: Public Variable Declarations

	/// Public Camera Delegate for the Custom View Controller Subclass

	public weak var cameraDelegate: SwiftyCamViewControllerDelegate?

	/// Maxiumum video duration if SwiftyCamButton is used

	public var maximumVideoDuration : Double     = 0.0

	/// Video capture quality

	public var videoQuality : VideoQuality       = .high

	/// Sets whether flash is enabled for photo and video capture

	public var flashEnabled                      = false

	/// Sets whether Pinch to Zoom is enabled for the capture session

	public var pinchToZoom                       = true

	/// Sets the maximum zoom scale allowed during gestures gesture

	public var maxZoomScale				         = CGFloat.greatestFiniteMagnitude
  
	/// Sets whether Tap to Focus and Tap to Adjust Exposure is enabled for the capture session

	public var tapToFocus                        = true

	/// Sets whether the capture session should adjust to low light conditions automatically
	///
	/// Only supported on iPhone 5 and 5C

	public var lowLightBoost                     = true

	/// Set whether SwiftyCam should allow background audio from other applications

	public var allowBackgroundAudio              = true

	/// Sets whether a double tap to switch cameras is supported

	public var doubleTapCameraSwitch            = true
    
    /// Sets whether swipe vertically to zoom is supported
    
    public var swipeToZoom                     = true
    
    /// Sets whether swipe vertically gestures should be inverted
    
    public var swipeToZoomInverted             = true

	/// Set default launch camera

	public var defaultCamera                   = CameraSelection.rear

	/// Sets wether the taken photo or video should be oriented according to the device orientation

	public var shouldUseDeviceOrientation      = false
    
    /// Sets whether or not View Controller supports auto rotation
    
    public var allowAutoRotate                = false
    
    /// Specifies the [videoGravity](https://developer.apple.com/reference/avfoundation/avcapturevideopreviewlayer/1386708-videogravity) for the preview layer.
    public var videoGravity                   : SwiftyCamVideoGravity = .resizeAspect
    
    /// Sets whether or not video recordings will record audio
    /// Setting to true will prompt user for access to microphone on View Controller launch.
    public var audioEnabled                   = true
    
    /// Public access to Pinch Gesture
    fileprivate(set) public var pinchGesture  : UIPinchGestureRecognizer!
    
    /// Public access to Pan Gesture
    fileprivate(set) public var panGesture    : UIPanGestureRecognizer!


	// MARK: Public Get-only Variable Declarations

	/// Returns true if video is currently being recorded

	private(set) public var isVideoRecording   = false
    
    
    /// Retruns true right after video is finished recording
    private(set) public var shouldRemoveVideoAudioInput   = false


	/// Returns true if the capture session is currently running

	private(set) public var isSessionRunning     = false

	/// Returns the CameraSelection corresponding to the currently utilized camera

	private(set) public var currentCamera        = CameraSelection.rear

	// MARK: Private Constant Declarations

	/// Current Capture Session

	public let session                           = AVCaptureSession()

	/// Serial queue used for setting up session

	fileprivate let sessionQueue                 = DispatchQueue(label: "session queue", attributes: [])

	// MARK: Private Variable Declarations

	/// Variable for storing current zoom scale

	fileprivate var zoomScale                    = CGFloat(1.0)

	/// Variable for storing initial zoom scale before Pinch to Zoom begins

	fileprivate var beginZoomScale               = CGFloat(1.0)

	/// Returns true if the torch (flash) is currently enabled

	fileprivate var isCameraTorchOn              = false

	/// Variable to store result of capture session setup

	fileprivate var setupResult                  = SessionSetupResult.success

	/// BackgroundID variable for video recording

	fileprivate var backgroundRecordingID        : UIBackgroundTaskIdentifier? = nil

	/// Video Input variable

	fileprivate var videoDeviceInput             : AVCaptureDeviceInput!

	/// Movie File Output variable

	fileprivate var movieFileOutput              : AVCaptureMovieFileOutput?

	/// Photo File Output variable

	fileprivate var photoFileOutput              : AVCaptureStillImageOutput?

	/// Video Device variable

	fileprivate var videoDevice                  : AVCaptureDevice?

	/// PreviewView for the capture session

	fileprivate var previewLayer                 : PreviewView!

	/// UIView for front facing flash

	fileprivate var flashView                    : UIView?
    
    /// Pan Translation
    
    fileprivate var previousPanTranslation       : CGFloat = 0.0

	/// Last changed orientation

	fileprivate var deviceOrientation            : UIDeviceOrientation?

	/// Disable view autorotation for forced portrait recorindg

	override open var shouldAutorotate: Bool {
		return allowAutoRotate
	}

	// MARK: ViewDidLoad

	/// ViewDidLoad Implementation
    public var pendingAddAudioInputCompletion = Promise<Void>.pending()
    var shouldChangeAudio = false
    var isLongPressing = false
    var startTime: Int! = 0
    var endTime: Int! = 0
    

	override open func viewDidLoad() {
		super.viewDidLoad()
        previewLayer = PreviewView(frame: view.frame, videoGravity: .resizeAspectFill) //videoGravity - .aspect
        //TODO: Use .aspect + fill up screen like snapchat camera (fullscreen images on iphone x)
        previewLayer.center = view.center
        view.addSubview(previewLayer)
        view.sendSubview(toBack: previewLayer)

		// Add Gesture Recognizers
        
        addGestureRecognizers()

		previewLayer.session = session

        
        //Request for Camera Permission
		switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo){
		case .authorized:
			// already authorized
			break
		case .notDetermined:
			// not yet determined
			sessionQueue.suspend()
			AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { [unowned self] granted in
				if !granted {
					self.setupResult = .notAuthorized
				}
				self.sessionQueue.resume()
			})
		default:
			// already been asked. Denied access
			setupResult = .notAuthorized
		}
        
        //Request Microphone Permission
        switch AVAudioSession.sharedInstance().recordPermission() {
        case AVAudioSessionRecordPermission.granted:
            break
        case AVAudioSessionRecordPermission.denied:
            break
        case AVAudioSessionRecordPermission.undetermined:
            sessionQueue.suspend()
            AVAudioSession.sharedInstance().requestRecordPermission {  [unowned self] granted in
                if granted {
                    print("Microphone Permission Authorized")
                }else{
                    print("Microphone Permission Not Authorized")
                }
                self.sessionQueue.resume()
            }
        default:
            break
        }
        
        
        //Configure AVCaptureSession
		sessionQueue.async { [unowned self] in
			self.configureSession()
		}
	}

    // MARK: ViewDidLayoutSubviews
    
    /// ViewDidLayoutSubviews() Implementation
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        //Override oreientation to be portrait
        layer.videoOrientation = .portrait //orientation
        
        previewLayer.frame = self.view.bounds
        
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let connection =  self.previewLayer?.videoPreviewLayer.connection  {
            
            let currentDevice: UIDevice = UIDevice.current
            
            let orientation: UIDeviceOrientation = currentDevice.orientation
            
            let previewLayerConnection : AVCaptureConnection = connection
            
            if previewLayerConnection.isVideoOrientationSupported {
                
                switch (orientation) {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                
                    break
                    
                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                
                    break
                    
                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                
                    break
                    
                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                
                    break
                    
                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                
                    break
                }
            }
        }
    }
	// MARK: ViewDidAppear

	/// ViewDidAppear(_ animated:) Implementation
	override open func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
        
        //Always Start w/ Inactive AVAudioSession
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("some error \(error) in SwiftyCamViewController.viewDidAppear(_ animated: Bool)")
        }
        //Always Set AVAudioSession to PlayAndRecord, in preparation for AVCaptureSession's addInput Audio
        //Setting this initially prevents initial glitch & dimming of session when audio input is added
        setBackgroundAudioPreference()

		// Subscribe to device rotation notifications
        
		if shouldUseDeviceOrientation {
			subscribeToDeviceOrientationChangeNotifications()
		}

		sessionQueue.async {
			switch self.setupResult {
			case .success:
				// Begin Session
				self.session.startRunning()
				self.isSessionRunning = self.session.isRunning
                
                // Preview layer video orientation can be set only after the connection is created
                DispatchQueue.main.async {
                    self.previewLayer.videoPreviewLayer.connection?.videoOrientation = self.getPreviewLayerOrientation()
                }
                
			case .notAuthorized:
				// Prompt to App Settings
				self.showCameraPermissionDeniedAlert()
			case .configurationFailed:
				// Unknown Error
                AlertUtils.showFCAlert(title: "Unable to Capture Media", subtitle: "Please make sure you've allowed Camera and Microphone access", image: nil, doneTitle: "Got It", buttons: nil, colorScheme: UIColor.flatRed)
			}
		}
	}

	// MARK: ViewDidDisappear
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // If session is running, stop the session
        if self.isSessionRunning == true {
            self.session.stopRunning()
            self.isSessionRunning = false
        }
        
        //Disble flash if it is currently enabled
        self.disableFlash()
        
        // Unsubscribe from device rotation notifications
        if self.shouldUseDeviceOrientation {
            self.unsubscribeFromDeviceOrientationChangeNotifications()
        }
        
        //Reset Default Inputs
        self.removeVideoAudioInput()
        
        // Change AudioSession Back
        AudioUtils.switchToAmbient(setActive: false)
    }

	/// ViewDidDisappear(_ animated:) Implementation
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
	// MARK: Public Functions

	/**

	Capture photo from current session

	UIImage will be returned with the SwiftyCamViewControllerDelegate function SwiftyCamDidTakePhoto(photo:)

	*/

	public func takePhoto() {
		guard let device = videoDevice else {
			return
		}

		if device.hasFlash == true && flashEnabled == true /* TODO: Add Support for Retina Flash and add front flash */ {
			changeFlashSettings(device: device, mode: .on)
			capturePhotoAsyncronously(completionHandler: { (_) in })

		} else if device.hasFlash == false && flashEnabled == true && currentCamera == .front {
			flashView = UIView(frame: view.frame)
			flashView?.alpha = 0.0
			flashView?.backgroundColor = UIColor.white
			previewLayer.addSubview(flashView!)

			UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
				self.flashView?.alpha = 1.0

			}, completion: { (_) in
				self.capturePhotoAsyncronously(completionHandler: { (success) in
					UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
						self.flashView?.alpha = 0.0
					}, completion: { (_) in
						self.flashView?.removeFromSuperview()
					})
				})
			})
		} else {
			if device.isFlashActive == true {
				changeFlashSettings(device: device, mode: .off)
			}
			capturePhotoAsyncronously(completionHandler: { (_) in })
		}
	}

	/**

	Begin recording video of current session

	SwiftyCamViewControllerDelegate function SwiftyCamDidBeginRecordingVideo() will be called

	*/

	public func startVideoRecording() {
//        print("Total Time for Video to Start: \(Date().millisecondsSince1970 - startTime)ms")
		guard let movieFileOutput = self.movieFileOutput else {
			return
		}
        
        
		if currentCamera == .rear && flashEnabled == true {
			enableFlash()
		}

		if currentCamera == .front && flashEnabled == true {
			flashView = UIView(frame: view.frame)
			flashView?.backgroundColor = UIColor.white
			flashView?.alpha = 0.85
			previewLayer.addSubview(flashView!)
		}
        
        //move begin recording video callback to sooner in order to have better perception of responsiveness ... at the expense of inaccurately indicating the recording has started while it has not
        DispatchQueue.main.async {
            self.cameraDelegate?.swiftyCam(self, didBeginRecordingVideo: self.currentCamera)
        }
        //print("\(Date().millisecondsSince1970 - startTime): 1...")
		sessionQueue.async { [unowned self] in
            //print("\(Date().millisecondsSince1970 - self.startTime): 2...")
			if !movieFileOutput.isRecording {
                //print("\(Date().millisecondsSince1970 - self.startTime): 3...")
				if UIDevice.current.isMultitaskingSupported {
					self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
				}

				// Update the orientation on the movie file output video connection before starting recording.
				let movieFileOutputConnection = self.movieFileOutput?.connection(withMediaType: AVMediaTypeVideo)


				//flip video output if front facing camera is selected
				if self.currentCamera == .front {
					movieFileOutputConnection?.isVideoMirrored = true
				}

				movieFileOutputConnection?.videoOrientation = self.getVideoOrientation()

				// Start recording to a temporary file.
				let outputFileName = UUID().uuidString
				let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
				movieFileOutput.startRecording(toOutputFileURL: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
				self.isVideoRecording = true
//                DispatchQueue.main.async {
//                    self.cameraDelegate?.swiftyCam(self, didBeginRecordingVideo: self.currentCamera)
//                }
                //print("\(Date().millisecondsSince1970 - self.startTime): 3.1...isRecording=\(movieFileOutput.isRecording)")
			}
			else {
                //print("\(Date().millisecondsSince1970 - self.startTime): 4...")
				movieFileOutput.stopRecording()
			}
            //print("\(Date().millisecondsSince1970 - self.startTime): 5...")
		}
	}

	/**

	Stop video recording video of current session

	SwiftyCamViewControllerDelegate function SwiftyCamDidFinishRecordingVideo() will be called

	When video has finished processing, the URL to the video location will be returned by SwiftyCamDidFinishProcessingVideoAt(url:)

	*/

    public func stopVideoRecording() {
        DispatchQueue.main.asyncAfter(deadline: .now()
          //  + 0.25
          //  + 0.08
            )
        { [unowned self] in  //250ms for adding audio input, and 80ms to because the there is a delay beween AVCaptureMovieFileOutput.startRecording and AVCaptureMovieFileOutput.isRecording(true). //also bump to 500ms because adding the audio input further delays the start of the video recording
            //print("\(Date().millisecondsSince1970 - self.startTime): stopVideoRecording--1... isRecording=\(String(describing: self.movieFileOutput?.isRecording))")
            if self.movieFileOutput?.isRecording == true {
                //print("\(Date().millisecondsSince1970 - self.startTime): stopVideoRecording--2...")
                self.isVideoRecording = false
                self.shouldRemoveVideoAudioInput = true
                self.movieFileOutput!.stopRecording()
                self.disableFlash()
                if self.currentCamera == .front && self.flashEnabled == true && self.flashView != nil {
                    UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
                        self.flashView?.alpha = 0.0
                    }, completion: { (_) in
                        self.flashView?.removeFromSuperview()
                    })
                }
                DispatchQueue.main.async {
                    self.cameraDelegate?.swiftyCam(self, didFinishRecordingVideo: self.currentCamera)
                }
            }
            //print("\(Date().millisecondsSince1970 - self.startTime): stopVideoRecording--3...")
        }
    }

	/**

	Switch between front and rear camera

	SwiftyCamViewControllerDelegate function SwiftyCamDidSwitchCameras(camera:  will be return the current camera selection

	*/


	public func switchCamera() {
		guard isVideoRecording != true else {
			//TODO: Look into switching camera during video recording
			print("[SwiftyCam]: Switching between cameras while recording video is not supported")
			return
		}
        
        guard session.isRunning == true else {
            return
        }
        
		switch currentCamera {
		case .front:
			currentCamera = .rear
		case .rear:
			currentCamera = .front
		}

		session.stopRunning()

		sessionQueue.async { [unowned self] in

			// remove and re-add inputs and outputs

			for input in self.session.inputs {
				self.session.removeInput(input as! AVCaptureInput)
			}

			self.addInputs()
			DispatchQueue.main.async {
				self.cameraDelegate?.swiftyCam(self, didSwitchCameras: self.currentCamera)
			}

			self.session.startRunning()
		}

		// If flash is enabled, disable it as the torch is needed for front facing camera
		disableFlash()
	}

	// MARK: Private Functions

	/// Configure session, add inputs and outputs

	fileprivate func configureSession() {
		guard setupResult == .success else {
			return
		}

		// Set default camera

		currentCamera = defaultCamera

		// begin configuring session

		session.beginConfiguration()
		configureVideoPreset()
//        addAudioInput()
		addVideoInput()
		configureVideoOutput()
		configurePhotoOutput()

		session.commitConfiguration()
	}

	/// Add inputs after changing camera()

	fileprivate func addInputs() {
		session.beginConfiguration()
		configureVideoPreset()
//        addAudioInput()
		addVideoInput()
		session.commitConfiguration()
	}
    
    
    fileprivate func addVideoAudioInput(){
        print("Adding Video Audio Input...")
        session.stopRunning()
        sessionQueue.async { [unowned self] in
            self.session.beginConfiguration()
            self.addAudioInput()
            self.session.commitConfiguration()
            self.session.startRunning()
            if self.pendingAddAudioInputCompletion.promise.isPending {
                self.pendingAddAudioInputCompletion.fulfill()
            }
        }
    }
    
    fileprivate func removeVideoAudioInput(){
        if shouldRemoveVideoAudioInput {
            print("Removing Video Audio Input...")
            sessionQueue.async { [unowned self] in
                // remove and re-add default inputs and outputs
                for input in self.session.inputs {
                    self.session.removeInput(input as! AVCaptureInput)
                }
                self.addInputs()
            }
            shouldRemoveVideoAudioInput = false
        }
    }


	// Front facing camera will always be set to VideoQuality.high
	// If set video quality is not supported, videoQuality variable will be set to VideoQuality.high
	/// Configure image quality preset

	fileprivate func configureVideoPreset() {
		if currentCamera == .front {
			session.sessionPreset = videoInputPresetFromVideoQuality(quality: .high)
		} else {
			if session.canSetSessionPreset(videoInputPresetFromVideoQuality(quality: videoQuality)) {
				session.sessionPreset = videoInputPresetFromVideoQuality(quality: videoQuality)
			} else {
				session.sessionPreset = videoInputPresetFromVideoQuality(quality: .high)
			}
		}
	}

	/// Add Video Inputs

	fileprivate func addVideoInput() {
		switch currentCamera {
		case .front:
			videoDevice = SwiftyCamViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: .front)
		case .rear:
			videoDevice = SwiftyCamViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: .back)
		}

		if let device = videoDevice {
			do {
				try device.lockForConfiguration()
				if device.isFocusModeSupported(.continuousAutoFocus) {
					device.focusMode = .continuousAutoFocus
					if device.isSmoothAutoFocusSupported {
						device.isSmoothAutoFocusEnabled = true
					}
				}

				if device.isExposureModeSupported(.continuousAutoExposure) {
					device.exposureMode = .continuousAutoExposure
				}

				if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
					device.whiteBalanceMode = .continuousAutoWhiteBalance
				}

				if device.isLowLightBoostSupported && lowLightBoost == true {
					device.automaticallyEnablesLowLightBoostWhenAvailable = true
				}

				device.unlockForConfiguration()
			} catch {
				print("[SwiftyCam]: Error locking configuration")
			}
		}

		do {
			let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

			if session.canAddInput(videoDeviceInput) {
				session.addInput(videoDeviceInput)
				self.videoDeviceInput = videoDeviceInput
			} else {
				print("[SwiftyCam]: Could not add video device input to the session")
				print(session.canSetSessionPreset(videoInputPresetFromVideoQuality(quality: videoQuality)))
				setupResult = .configurationFailed
				session.commitConfiguration()
				return
			}
		} catch {
			print("[SwiftyCam]: Could not create video device input: \(error)")
			setupResult = .configurationFailed
			return
		}
	}

	/// Add Audio Inputs

	fileprivate func addAudioInput() {
        guard audioEnabled == true else {
            return
        }
		do {
			let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
			let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)

			if session.canAddInput(audioDeviceInput) {
				session.addInput(audioDeviceInput)
			}
			else {
				print("[SwiftyCam]: Could not add audio device input to the session")
			}
		}
		catch {
			print("[SwiftyCam]: Could not create audio device input: \(error)")
		}
	}
    
    
    fileprivate func removeAudioInput() {
        do {
            let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            session.removeInput(audioDeviceInput)
        }
        catch {
            print("[SwiftyCam]: Could not create audio device input: \(error)")
        }
    }

	/// Configure Movie Output

	fileprivate func configureVideoOutput() {
		let movieFileOutput = AVCaptureMovieFileOutput()

		if self.session.canAddOutput(movieFileOutput) {
			self.session.addOutput(movieFileOutput)
			if let connection = movieFileOutput.connection(withMediaType: AVMediaTypeVideo) {
				if connection.isVideoStabilizationSupported {
					connection.preferredVideoStabilizationMode = .auto
				}
			}
			self.movieFileOutput = movieFileOutput
		}
	}

	/// Configure Photo Output

	fileprivate func configurePhotoOutput() {
		let photoFileOutput = AVCaptureStillImageOutput()

		if self.session.canAddOutput(photoFileOutput) {
			photoFileOutput.outputSettings  = [AVVideoCodecKey: AVVideoCodecJPEG]
			self.session.addOutput(photoFileOutput)
			self.photoFileOutput = photoFileOutput
		}
	}

	/// Orientation management

	fileprivate func subscribeToDeviceOrientationChangeNotifications() {
		self.deviceOrientation = UIDevice.current.orientation
		NotificationCenter.default.addObserver(self, selector: #selector(deviceDidRotate), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
	}

	fileprivate func unsubscribeFromDeviceOrientationChangeNotifications() {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
		self.deviceOrientation = nil
	}

	@objc fileprivate func deviceDidRotate() {
		if !UIDevice.current.orientation.isFlat {
			self.deviceOrientation = UIDevice.current.orientation
		}
	}
    
    fileprivate func getPreviewLayerOrientation() -> AVCaptureVideoOrientation {
        // Depends on layout orientation, not device orientation
        switch UIApplication.shared.statusBarOrientation {
        case .portrait, .unknown:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        }
    }

	fileprivate func getVideoOrientation() -> AVCaptureVideoOrientation {
		guard shouldUseDeviceOrientation, let deviceOrientation = self.deviceOrientation else { return previewLayer!.videoPreviewLayer.connection.videoOrientation }

		switch deviceOrientation {
		case .landscapeLeft:
			return .landscapeRight
		case .landscapeRight:
			return .landscapeLeft
		case .portraitUpsideDown:
			return .portraitUpsideDown
		default:
			return .portrait
		}
	}

	fileprivate func getImageOrientation(forCamera: CameraSelection) -> UIImageOrientation {
		guard shouldUseDeviceOrientation, let deviceOrientation = self.deviceOrientation else { return forCamera == .rear ? .right : .leftMirrored }

		switch deviceOrientation {
		case .landscapeLeft:
			return forCamera == .rear ? .up : .downMirrored
		case .landscapeRight:
			return forCamera == .rear ? .down : .upMirrored
		case .portraitUpsideDown:
			return forCamera == .rear ? .left : .rightMirrored
		default:
			return forCamera == .rear ? .right : .leftMirrored
		}
	}

	/**
	Returns a UIImage from Image Data.

	- Parameter imageData: Image Data returned from capturing photo from the capture session.

	- Returns: UIImage from the image data, adjusted for proper orientation.
	*/

	fileprivate func processPhoto(_ imageData: Data) -> UIImage {
		let dataProvider = CGDataProvider(data: imageData as CFData)
		let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)

		// Set proper orientation for photo
		// If camera is currently set to front camera, flip image

		let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: self.getImageOrientation(forCamera: self.currentCamera))

		return image
	}

	fileprivate func capturePhotoAsyncronously(completionHandler: @escaping(Bool) -> ()) {
		if let videoConnection = photoFileOutput?.connection(withMediaType: AVMediaTypeVideo) {

			photoFileOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: {(sampleBuffer, error) in
				if (sampleBuffer != nil) {
					let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
					let image = self.processPhoto(imageData!)

					// Call delegate and return new image
					DispatchQueue.main.async {
						self.cameraDelegate?.swiftyCam(self, didTake: image)
					}
					completionHandler(true)
				} else {
					completionHandler(false)
				}
			})
		} else {
			completionHandler(false)
		}
	}

	/// Handle Denied App Privacy Settings
    
    fileprivate func showCameraPermissionDeniedAlert(){
        AlertUtils.showFCAlertP(title: "Unable to Access Camera", subtitle: "Please allow camera access for taking pictures and videos.", image: nil, doneTitle: "Allow", buttons: ["Cancel"], colorScheme: UIColor.flatRed)
            .then{ index -> Void in
                if index == AlertUtils.BTN_DONE {
                    CommonUtils.goToAppSettings()
                    
                }
            }
            .catch{err in
                print("\(err)")
        }
    }
    
    fileprivate func showMicrophonePermissionDeniedAlert(){
        AlertUtils.showFCAlertP(title: "Unable to Access Microphone", subtitle: "Please allow microphone access for recording videos.", image: nil, doneTitle: "Allow", buttons: ["Cancel"], colorScheme: UIColor.flatRed)
            .then{ index -> Void in
                if index == AlertUtils.BTN_DONE {
                    CommonUtils.goToAppSettings()

                }
            }
            .catch{err in
                print("\(err)")
        }
    }

	/**
	Returns an AVCapturePreset from VideoQuality Enumeration

	- Parameter quality: ViewQuality enum

	- Returns: String representing a AVCapturePreset
	*/

	fileprivate func videoInputPresetFromVideoQuality(quality: VideoQuality) -> String {
		switch quality {
		case .high: return AVCaptureSessionPresetHigh
		case .medium: return AVCaptureSessionPresetMedium
		case .low: return AVCaptureSessionPresetLow
		case .resolution352x288: return AVCaptureSessionPreset352x288
		case .resolution640x480: return AVCaptureSessionPreset640x480
		case .resolution1280x720: return AVCaptureSessionPreset1280x720
		case .resolution1920x1080: return AVCaptureSessionPreset1920x1080
		case .iframe960x540: return AVCaptureSessionPresetiFrame960x540
		case .iframe1280x720: return AVCaptureSessionPresetiFrame1280x720
		case .resolution3840x2160:
			if #available(iOS 9.0, *) {
				return AVCaptureSessionPreset3840x2160
			}
			else {
				print("[SwiftyCam]: Resolution 3840x2160 not supported")
				return AVCaptureSessionPresetHigh
			}
		}
	}

	/// Get Devices

	fileprivate class func deviceWithMediaType(_ mediaType: String, preferringPosition position: AVCaptureDevicePosition) -> AVCaptureDevice? {
		if let devices = AVCaptureDevice.devices(withMediaType: mediaType) as? [AVCaptureDevice] {
			return devices.filter({ $0.position == position }).first
		}
		return nil
	}

	/// Enable or disable flash for photo

	fileprivate func changeFlashSettings(device: AVCaptureDevice, mode: AVCaptureFlashMode) {
		do {
			try device.lockForConfiguration()
			device.flashMode = mode
			device.unlockForConfiguration()
		} catch {
			print("[SwiftyCam]: \(error)")
		}
	}

	/// Enable flash

	fileprivate func enableFlash() {
		if self.isCameraTorchOn == false {
			toggleFlash()
		}
	}

	/// Disable flash

	fileprivate func disableFlash() {
		if self.isCameraTorchOn == true {
			toggleFlash()
		}
	}

	/// Toggles between enabling and disabling flash

	fileprivate func toggleFlash() {
		guard self.currentCamera == .rear else {
			// Flash is not supported for front facing camera
			return
		}

		let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
		// Check if device has a flash
		if (device?.hasTorch)! {
			do {
				try device?.lockForConfiguration()
				if (device?.torchMode == AVCaptureTorchMode.on) {
					device?.torchMode = AVCaptureTorchMode.off
					self.isCameraTorchOn = false
				} else {
					do {
						try device?.setTorchModeOnWithLevel(1.0)
						self.isCameraTorchOn = true
					} catch {
						print("[SwiftyCam]: \(error)")
					}
				}
				device?.unlockForConfiguration()
			} catch {
				print("[SwiftyCam]: \(error)")
			}
		}
	}

	/// Sets whether SwiftyCam should enable background audio from other applications or sources

	fileprivate func setBackgroundAudioPreference() {
		guard allowBackgroundAudio == true else {
			return
		}
        
        guard audioEnabled == true else {
            return
        }
        session.automaticallyConfiguresApplicationAudioSession = false
		do{
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord,
                                                                with: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            } else {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord,
                                                                with: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth])
            }
		}
		catch {
			print("[SwiftyCam]: Failed to set background audio preference")

		}
	}
    
    fileprivate func setAmbientAudioPreference() {
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            AVCaptureSession().automaticallyConfiguresApplicationAudioSession = false
        }
        catch {
            print("[SwiftyCam]: Failed to set ambient audio preference")
            
        }
    }
}

extension SwiftyCamViewController : SwiftyCamButtonDelegate {

	/// Sets the maximum duration of the SwiftyCamButton

	public func setMaxiumVideoDuration() -> Double {
		return maximumVideoDuration
	}

    
    //Override these methods on CameraViewController (inherits from SwiftyCamViewController)
    public func buttonTouchesBegan(){}
    public func buttonTouchesEnded(){}
    public func buttonTouchesCancelled(){}
    
	/// Set UITapGesture to take photo

	public func buttonWasTapped() {
        if isVideoRecording {
            print("Video Capture: Stopping recording due to tap")
            stopVideoRecording()
        } else{
            takePhoto()
        }
	}

	/// Set UILongPressGesture start to begin video

	public func buttonDidBeginLongPress() {
        guard  AVAudioSession.sharedInstance().recordPermission() == .granted else {
            showMicrophonePermissionDeniedAlert()
            return
        }
        isLongPressing = true //Prevent touchesCancelled from shrinking button
        print("Video Capture: Touch is longer than 250ms (LongPressed)")
        guard isVideoRecording == false else { return }
        print("Video Capture: Adding video audio due to long press...")
        self.pendingAddAudioInputCompletion = Promise<Void>.pending()
        _=self.pendingAddAudioInputCompletion.promise
            .then{_ -> Void in
                print("Video Capture: Audio added. Starting to record...")
                self.startVideoRecording()
        }
        self.addVideoAudioInput()
	}

	/// Set UILongPressGesture begin to begin end video


	public func buttonDidEndLongPress() {
        //print("\(Date().millisecondsSince1970 - startTime): buttonDidEndLongPress...")
        isLongPressing = false
        print("Video Capture: Long press gesture ended")
        guard isVideoRecording else { return }
        print("Video Capture: Stopping recording due to ended long press")
		stopVideoRecording()
	}

	/// Called if maximum duration is reached

	public func longPressDidReachMaximumDuration() {
        print("Video Capture: Long press maximum duration reached")
        guard isVideoRecording else { return }
        print("Video Capture: Stopping recording due to reaching maximum duration")
		stopVideoRecording()
	}
}

// MARK: AVCaptureFileOutputRecordingDelegate

extension SwiftyCamViewController : AVCaptureFileOutputRecordingDelegate {

	/// Process newly captured video and write it to temporary directory

	public func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
		if let currentBackgroundRecordingID = backgroundRecordingID {
			backgroundRecordingID = UIBackgroundTaskInvalid

			if currentBackgroundRecordingID != UIBackgroundTaskInvalid {
				UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
			}
		}
		if error != nil {
			print("[SwiftyCam]: Movie file finishing error: \(error)")
            DispatchQueue.main.async {
                self.cameraDelegate?.swiftyCam(self, didFailToRecordVideo: error)
            }
		} else {
			//Call delegate function with the URL of the outputfile
			DispatchQueue.main.async {
				self.cameraDelegate?.swiftyCam(self, didFinishProcessVideoAt: outputFileURL)
			}
		}
	}
}

// Mark: UIGestureRecognizer Declarations

extension SwiftyCamViewController {

	/// Handle pinch gesture

	@objc fileprivate func zoomGesture(pinch: UIPinchGestureRecognizer) {
		guard pinchToZoom == true && self.currentCamera == .rear else {
			//ignore pinch 
			return
		}
		do {
			let captureDevice = AVCaptureDevice.devices().first as? AVCaptureDevice
			try captureDevice?.lockForConfiguration()

			zoomScale = min(maxZoomScale, max(1.0, min(beginZoomScale * pinch.scale,  captureDevice!.activeFormat.videoMaxZoomFactor)))

			captureDevice?.videoZoomFactor = zoomScale

			// Call Delegate function with current zoom scale
			DispatchQueue.main.async {
				self.cameraDelegate?.swiftyCam(self, didChangeZoomLevel: self.zoomScale)
			}

			captureDevice?.unlockForConfiguration()

		} catch {
			print("[SwiftyCam]: Error locking configuration")
		}
	}

	/// Handle single tap gesture

	@objc fileprivate func singleTapGesture(tap: UITapGestureRecognizer) {
		guard tapToFocus == true else {
			// Ignore taps
			return
		}

		let screenSize = previewLayer!.bounds.size
		let tapPoint = tap.location(in: previewLayer!)
		let x = tapPoint.y / screenSize.height
		let y = 1.0 - tapPoint.x / screenSize.width
		let focusPoint = CGPoint(x: x, y: y)

		if let device = videoDevice {
			do {
				try device.lockForConfiguration()

				if device.isFocusPointOfInterestSupported == true {
					device.focusPointOfInterest = focusPoint
					device.focusMode = .autoFocus
				}
				device.exposurePointOfInterest = focusPoint
				device.exposureMode = AVCaptureExposureMode.continuousAutoExposure
				device.unlockForConfiguration()
				//Call delegate function and pass in the location of the touch

				DispatchQueue.main.async {
					self.cameraDelegate?.swiftyCam(self, didFocusAtPoint: tapPoint)
				}
			}
			catch {
				// just ignore
			}
		}
	}

	/// Handle double tap gesture

	@objc fileprivate func doubleTapGesture(tap: UITapGestureRecognizer) {
		guard doubleTapCameraSwitch == true else {
			return
		}
		switchCamera()
	}
    
    @objc private func panGesture(pan: UIPanGestureRecognizer) {
        
        guard swipeToZoom == true else {
            //ignore pan
            return
        }
        let currentTranslation    = pan.translation(in: view).y
        let translationDifference = currentTranslation - previousPanTranslation
        
        do {
            let devicePosition: AVCaptureDevicePosition = self.currentCamera == .rear ? AVCaptureDevicePosition.back : AVCaptureDevicePosition.front
            let deviceCount = AVCaptureDevice.devices().count
            guard deviceCount > 0, let captureDevice = AVCaptureDevice.devices().first(where: {($0 as! AVCaptureDevice).position == devicePosition}) as? AVCaptureDevice else {
                return
            }
            try captureDevice.lockForConfiguration()
            let currentZoom = captureDevice.videoZoomFactor
            if swipeToZoomInverted == true {
                zoomScale = min(maxZoomScale, max(1.0, min(currentZoom - (translationDifference / 75),  captureDevice.activeFormat.videoMaxZoomFactor)))
            } else {
                zoomScale = min(maxZoomScale, max(1.0, min(currentZoom + (translationDifference / 75),  captureDevice.activeFormat.videoMaxZoomFactor)))

            }
            captureDevice.videoZoomFactor = zoomScale
            // Call Delegate function with current zoom scale
            DispatchQueue.main.async {
                self.cameraDelegate?.swiftyCam(self, didChangeZoomLevel: self.zoomScale)
            }
            
            captureDevice.unlockForConfiguration()
            
        } catch {
            print("[SwiftyCam]: Error locking configuration")
        }
        
        if pan.state == .ended || pan.state == .failed || pan.state == .cancelled {
            previousPanTranslation = 0.0
        } else {
            previousPanTranslation = currentTranslation
        }
    }

	/**
	Add pinch gesture recognizer and double tap gesture recognizer to currentView

	- Parameter view: View to add gesture recognzier

	*/

	fileprivate func addGestureRecognizers() {
		pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoomGesture(pinch:)))
		pinchGesture.delegate = self
		previewLayer.addGestureRecognizer(pinchGesture)

		let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapGesture(tap:)))
		singleTapGesture.numberOfTapsRequired = 1
		singleTapGesture.delegate = self
		previewLayer.addGestureRecognizer(singleTapGesture)

		let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapGesture(tap:)))
		doubleTapGesture.numberOfTapsRequired = 2
		doubleTapGesture.delegate = self
		previewLayer.addGestureRecognizer(doubleTapGesture)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture(pan:)))
        panGesture.delegate = self
        previewLayer.addGestureRecognizer(panGesture)
	}
}


// MARK: UIGestureRecognizerDelegate

extension SwiftyCamViewController : UIGestureRecognizerDelegate {

	/// Set beginZoomScale when pinch begins

	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) {
			beginZoomScale = zoomScale;
		}
		return true
	}
}




