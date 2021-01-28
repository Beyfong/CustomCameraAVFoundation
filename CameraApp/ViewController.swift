//
//  ViewController.swift
//  CameraApp
//
//  Created by ablai erzhanov on 1/19/21.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate{
     
    
    
    // MARK: -Properties-
    
    let captureSession = AVCaptureSession()

    let movieOutput = AVCaptureMovieFileOutput()

    var previewLayer: AVCaptureVideoPreviewLayer!
    
    let output = AVCapturePhotoOutput()
    
    let videoOutput = AVCaptureMovieFileOutput()
    
    var videoCaptureDevice: AVCaptureDevice!
    
    var captureAudio :AVCaptureDevice!
    
    var backCamera : AVCaptureDevice!
    var frontCamera : AVCaptureDevice!
    
    var backCameraInput : AVCaptureInput!
    var frontCameraInput : AVCaptureInput!
    
    var backVideoInput: AVCaptureMovieFileOutput!
    var frontVideoInput: AVCaptureMovieFileOutput!
    
    var backInput : AVCaptureInput!
    var frontInput : AVCaptureInput!
    
    var captureAudioInput: AVCaptureInput!
    
    var backCameraOn = true
    
    var imagePicker = UIImagePickerController()
    
    // MARK: -Outlets-
    
    let capturePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        let image = #imageLiteral(resourceName: "Shoot Button")
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(handlePhotoButton), for: .touchUpInside)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 2
        button.addGestureRecognizer(longPressGesture)
        return button
    }()

    let switchButton: UIButton = {
        let button =  UIButton(type: .system)
        let image = #imageLiteral(resourceName: "switch-camera")
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        return button
    }()
    
    let galleryButton: UIButton = {
        let button = UIButton(type: .system)
        let image = #imageLiteral(resourceName: "gallery")
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(galleryTapped), for: .touchUpInside)
        return button
    }()
    
    let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        let image = #imageLiteral(resourceName: "cancel")
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        return button
    }()
    
    // MARK: -LifeCycle-
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        configureUI()
        
    }
    
    // MARK: -Actions-
    
    @objc private func handlePhotoButton(){
        let settings = AVCapturePhotoSettings()
        
        guard let previewFormatType = settings.availablePreviewPhotoPixelFormatTypes.first else {return}
        settings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewFormatType]
        
        output.capturePhoto(with: settings, delegate: self)
        
    }
    
    @objc private func switchCamera(){
        switchCameraInput()
    }
    
    @objc private func galleryTapped(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false

            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @objc private func handleDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleLongPress() {
        if videoOutput.isRecording {
            videoOutput.stopRecording()
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let fileUrl = paths[0].appendingPathComponent("output.mov")
            try? FileManager.default.removeItem(at: fileUrl)
            videoOutput.startRecording(to: fileUrl, recordingDelegate: self)
        }
    }
    
    // MARK: -Helpers-
    
    private func setupCaptureSession(){
        
        //1 setup Inputs
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return  }
        
//        do {
//            let input = try AVCaptureDeviceInput(device: captureDevice)
//            if captureSession.canAddInput(input){
//                captureSession.addInput(input)
//            }
//        } catch let error {
//            print("DEBUG:\(error)")
//        }
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            backCamera = device
        } else {
            fatalError("no back camera")
        }
        
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video
                                                , position: .front){
            frontCamera = device
        } else {
            fatalError("no front camera")
        }
        
        guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError("couldn't create input device from backCamera")
        }
        
        backInput = bInput
        if !captureSession.canAddInput(backInput) {
            fatalError("Couldn't add back input to capture session")
        }
        
        guard let fInput = try? AVCaptureDeviceInput(device: frontCamera) else {
            fatalError("couldn't create input device from frontCamera")
        }
        
        frontInput = fInput
        
        if !captureSession.canAddInput(frontInput){
            fatalError("Couldn't add front input to capture session")
        }
        
        //connect back camera input to session
        if captureSession.canAddInput(backInput) {
            captureSession.addInput(backInput)
        }
 
//        if captureSession.canAddInput(backCameraInput){
//            captureSession.addInput(backCameraInput)
//        }
//
//        if captureSession.canAddInput(captureAudioInput){
//            captureSession.addInput(captureAudioInput)
//        }
        
//        if let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] {
//            for device in devices {
//                if device.hasMediaType(AVMediaType.video) {
//                    if device .position == AVCaptureDevice.Position.back{
//            videoCaptureDevice = device
//                    }
//                }
//            }
//        }
//
//        if videoCaptureDevice != nil {
//            do {
//                try captureSession.addInput(AVCaptureDeviceInput(device: videoCaptureDevice))
//
//                guard let audioInput = AVCaptureDevice.default(for: AVMediaType.audio) else { return  }
//                try captureSession.addInput(AVCaptureDeviceInput(device: audioInput))
//            } catch let error {
//                print("DEBUG: \(error)")
//            }
//        }
        
        
        //2 setup Outputs
    
        if captureSession.canAddOutput(output){
            captureSession.addOutput(output)
        }
        
//        if captureSession.canAddOutput(videoOutput){
//            captureSession.addOutput(videoOutput)
//        }
        
        //3 setup Output Preview
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(previewLayer!)
        captureSession.startRunning()
    }

    private func configureUI(){
        view.addSubview(capturePhotoButton)
        capturePhotoButton.anchor(top: nil, left: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 24, paddingRight: 0, width: 80, height: 80)
        capturePhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(switchButton)
        switchButton.anchor( bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingBottom: 24, paddingRight: 16, width: 60, height: 60)
        
        view.addSubview(galleryButton)
        galleryButton.anchor(left: view.safeAreaLayoutGuide.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingLeft: 16, paddingBottom: 24, width: 60, height: 60)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer!)
        
        let previewImage = UIImage(data: imageData!)
        
        let previewImageView = UIImageView(image: previewImage)
        view.addSubview(previewImageView)
        previewImageView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }
    
    func switchCameraInput() {
        switchButton.isUserInteractionEnabled = false
        
//        captureSession.startRunning()
        
        if backCameraOn {
            captureSession.removeInput(backInput)
            captureSession.addInput(frontInput)
            backCameraOn = false
        } else {
            captureSession.removeInput(frontInput)
            captureSession.addInput(backInput)
            backCameraOn = true
        }
        
        output.connections.first?.videoOrientation = .portrait
        output.connections.first?.isVideoMirrored = !backCameraOn
        switchButton.isUserInteractionEnabled = true
        
    }
}





// MARK: -EXTENSIONS-
extension ViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let videoRecordedURL = outputFileURL as URL
        print("Successfully captured video")
        var video = NSData.dataWithContentsOfMappedFile("\(videoRecordedURL)")
        view.addSubview(video as! UIView)
        
    }
}


// MARK: -Extension fro ImagePicker-
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            DispatchQueue.main.async {
                let previewImageView = UIImageView(image: image)
                self.imagePicker.dismiss(animated: true, completion: nil)
                self.view.addSubview(previewImageView)
                previewImageView.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            }
        }
    }
}
