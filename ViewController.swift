//
//  ViewController.swift
//  Night
//
//  Created by 海鋒健太 on 2015/10/06.
//  Copyright © 2015年 海鋒健太. All rights reserved.
//

import UIKit
import GLKit
import AVFoundation
import CoreImage

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate
{
    var videoDisplayView: GLKView!
    var videoDisplayViewRect: CGRect!
    var renderContext: CIContext!
    var cpsSession: AVCaptureSession!
    var number: Int = 0
    var iso: Float = 0.5
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        
    }
    override func viewWillAppear(animated: Bool)
    {
        //画面の生成
        self.initDisplay()
        
        // カメラの使用準備.
        self.initCamera()
        
        let b1: UIButton = UIButton(frame: CGRectMake(10, self.view.frame.height - 80, 50, 50))
        b1.backgroundColor = UIColor.whiteColor()
        b1.addTarget(self, action: "tap:", forControlEvents: .TouchDown)
        b1.tag = 0
        let b2: UIButton = UIButton(frame: CGRectMake(70, self.view.frame.height - 80, 50, 50))
        b2.backgroundColor = UIColor.redColor()
        b2.addTarget(self, action: "tap:", forControlEvents: .TouchDown)
        b2.tag = 1
        let b3: UIButton = UIButton(frame: CGRectMake(130, self.view.frame.height - 80, 50, 50))
        b3.backgroundColor = UIColor.blueColor()
        b3.addTarget(self, action: "tap:", forControlEvents: .TouchDown)
        b3.tag = 2
        let b4: UIButton = UIButton(frame: CGRectMake(190, self.view.frame.height - 80, 50, 50))
        b4.backgroundColor = UIColor.greenColor()
        b4.addTarget(self, action: "tap:", forControlEvents: .TouchDown)
        b4.tag = 3
        self.view.addSubview(b1)
        self.view.addSubview(b2)
        self.view.addSubview(b3)
        self.view.addSubview(b4)
        let myGreenSlider = UISlider(frame: CGRectMake(0, 0, 200, 30))
        myGreenSlider.layer.position = CGPointMake(self.view.frame.midX, 300)
        myGreenSlider.backgroundColor = UIColor.whiteColor()
        myGreenSlider.layer.cornerRadius = 10.0
        myGreenSlider.layer.shadowOpacity = 0.5
        myGreenSlider.layer.masksToBounds = false
        myGreenSlider.minimumValue = 0
        myGreenSlider.maximumValue = 1
        
        // Sliderの位置を設定する.
        myGreenSlider.value = 0.5
        
        // Sliderの現在位置より右のTintカラーを変える.
        myGreenSlider.maximumTrackTintColor = UIColor.grayColor()
        
        // Sliderの現在位置より左のTintカラーを変える.
        myGreenSlider.minimumTrackTintColor = UIColor.blackColor()
        
        myGreenSlider.addTarget(self, action: "onChangeValueMySlider:", forControlEvents: UIControlEvents.ValueChanged)
        
        self.view.addSubview(myGreenSlider)
    }
    override func viewDidDisappear(animated: Bool)
    {
        // カメラの停止とメモリ解放.
        self.cpsSession.stopRunning()
        for output in self.cpsSession.outputs
        {
            self.cpsSession.removeOutput(output as! AVCaptureOutput)
        }
        for input in self.cpsSession.inputs
        {
            self.cpsSession.removeInput(input as! AVCaptureInput)
        }
        self.cpsSession = nil
    }
    func initDisplay()
    {
        let aSelector = Selector("tapGesture:")
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: aSelector)
        videoDisplayView = GLKView(frame: view.bounds, context: EAGLContext(API: .OpenGLES2))
        videoDisplayView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        videoDisplayView.frame = view.bounds
        videoDisplayView.addGestureRecognizer(tapGestureRecognizer)
        view.addSubview(videoDisplayView)
        
        renderContext = CIContext(EAGLContext: videoDisplayView.context)
        videoDisplayView.bindDrawable()
        videoDisplayViewRect = CGRect(x: 0, y: 0, width: videoDisplayView.drawableWidth, height: videoDisplayView.drawableHeight)
    }
    func initCamera()
    {
        //カメラからの入力を作成
        var device: AVCaptureDevice!
        
        //背面カメラの検索
        for d: AnyObject in AVCaptureDevice.devices()
        {
            if d.position == AVCaptureDevicePosition.Back
            {
                device = d as! AVCaptureDevice
                do{
                    try device.lockForConfiguration()
                    device.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: (device.activeFormat.maxISO - device.activeFormat.minISO) * iso + device.activeFormat.minISO, completionHandler: nil)
                    device.unlockForConfiguration()
                }catch{
                    print("無理")
                }

            }
        }
        
        //入力データの取得
        var deviceInput: AVCaptureDeviceInput = try! AVCaptureDeviceInput(device: device)
        //出力データの取得
        var videoDataOutput:AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        
        //カラーチャンネルの設定
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
        
        //画像をキャプチャするキューを指定
        videoDataOutput.setSampleBufferDelegate(self, queue: dispatch_get_main_queue())
        
        //キューがブロックされているときに新しいフレームが来たら削除
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        //セッションの使用準備
        self.cpsSession = AVCaptureSession()
        
        //Input
        if(self.cpsSession.canAddInput(deviceInput))
        {
            self.cpsSession.addInput(deviceInput as AVCaptureDeviceInput)
        }
        //Output
        if(self.cpsSession.canAddOutput(videoDataOutput))
        {
            self.cpsSession.addOutput(videoDataOutput)
        }
        //解像度の指定
        self.cpsSession.sessionPreset = AVCaptureSessionPresetMedium
        
        self.cpsSession.startRunning()
    }
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    {
        //SampleBufferから画像を取得
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let opaqueBuffer = Unmanaged<CVImageBuffer>.passUnretained(imageBuffer!).toOpaque()
        let pixelBuffer = Unmanaged<CVPixelBuffer>.fromOpaque(opaqueBuffer).takeUnretainedValue()
        let outputImage = CIImage(CVPixelBuffer: pixelBuffer, options: nil)
        let ciFilter:CIFilter!
        switch self.number {
        case 0:
            ciFilter = CIFilter(name: "CIToneCurve" )!
            ciFilter.setValue(outputImage, forKey: kCIInputImageKey)
            ciFilter.setValue(CIVector(x: 0.0, y: 0.0), forKey: "inputPoint0")
            ciFilter.setValue(CIVector(x: 0.25, y: 0.1), forKey: "inputPoint1")
            ciFilter.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2")
            ciFilter.setValue(CIVector(x: 0.75, y: 9.0), forKey: "inputPoint3")
            ciFilter.setValue(CIVector(x: 1.0, y: 1.0), forKey: "inputPoint4")
            break
        case 1:
            ciFilter = CIFilter(name: "CIToneCurve" )!
            ciFilter.setValue(outputImage, forKey: kCIInputImageKey)
            ciFilter.setValue(CIVector(x: 0.0, y: 0.0), forKey: "inputPoint0")
            ciFilter.setValue(CIVector(x: 0.25, y: 0.6), forKey: "inputPoint1")
            ciFilter.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2")
            ciFilter.setValue(CIVector(x: 0.75, y: 0.4), forKey: "inputPoint3")
            ciFilter.setValue(CIVector(x: 1.0, y: 1.0), forKey: "inputPoint4")
            break
        case 2:
            ciFilter = CIFilter(name: "CIToneCurve" )!
            ciFilter.setValue(outputImage, forKey: kCIInputImageKey)
            ciFilter.setValue(CIVector(x: 0.0, y: 0.0), forKey: "inputPoint0")
            ciFilter.setValue(CIVector(x: 0.25, y: 0.25), forKey: "inputPoint1")
            ciFilter.setValue(CIVector(x: 0.5, y: 0.7), forKey: "inputPoint2")
            ciFilter.setValue(CIVector(x: 0.75, y: 0.95), forKey: "inputPoint3")
            ciFilter.setValue(CIVector(x: 1.0, y: 1.0), forKey: "inputPoint4")
            break
        case 3:
            ciFilter = CIFilter(name: "CIColorControls" )
            ciFilter.setValue(outputImage, forKey: kCIInputImageKey)
            ciFilter.setValue(1.2, forKey: "inputSaturation")
            ciFilter.setValue(1.3, forKey: "inputBrightness")
            ciFilter.setValue(3.6, forKey: "inputContrast")
            break
        default:
            ciFilter = CIFilter(name: "CIToneCurve" )!
            ciFilter.setValue(outputImage, forKey: kCIInputImageKey)
            ciFilter.setValue(CIVector(x: 0.0, y: 0.0), forKey: "inputPoint0")
            ciFilter.setValue(CIVector(x: 0.25, y: 0.25), forKey: "inputPoint1")
            ciFilter.setValue(CIVector(x: 0.5, y: 0.7), forKey: "inputPoint2")
            ciFilter.setValue(CIVector(x: 0.75, y: 0.95), forKey: "inputPoint3")
            ciFilter.setValue(CIVector(x: 1.0, y: 1.0), forKey: "inputPoint4")
            break
        }
        
        let oi = ciFilter.outputImage!
        
        //補正
        var drawFrame = ciFilter.outputImage!.extent
        let imageAR = drawFrame.width / drawFrame.height
        let viewAR = videoDisplayViewRect.width / videoDisplayViewRect.height
        if imageAR > viewAR {
            drawFrame.origin.x += (drawFrame.width - drawFrame.height * viewAR) / 2.0
            drawFrame.size.width = drawFrame.height / viewAR
        } else {
            drawFrame.origin.y += (drawFrame.height - drawFrame.width / viewAR) / 2.0
            drawFrame.size.height = drawFrame.width / viewAR
        }
        
        //出力
        videoDisplayView.bindDrawable()
        if videoDisplayView.context != EAGLContext.currentContext() {
            EAGLContext.setCurrentContext(videoDisplayView.context)
        }
        renderContext.drawImage(oi, inRect: videoDisplayViewRect, fromRect: drawFrame)
        videoDisplayView.display()
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    internal func tap(sender: UIButton){
        self.number = sender.tag
        self.initCamera()
    }
    
    func tapGesture(gestureRecognizer: UITapGestureRecognizer){
        self.view.endEditing(true)
        if gestureRecognizer.state == UIGestureRecognizerState.Ended {
            let tapPoint = gestureRecognizer.locationInView(view)
            let location: CGPoint = tapPoint //UITouchなどから取得した位置
            let viewSize: CGSize = self.view.bounds.size;
            let pointOfInterest: CGPoint = CGPointMake(location.y / viewSize.height, 1.0 - location.x / viewSize.width);
            let camera: AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
            if(camera.isFocusModeSupported(AVCaptureFocusMode.AutoFocus)) {
                do{
                    try camera.lockForConfiguration()
                    camera.focusPointOfInterest = pointOfInterest
                    camera.focusMode = AVCaptureFocusMode.AutoFocus
                    camera.unlockForConfiguration()
                }catch{
                    
                }
            }
        }
    }
    
    internal func onChangeValueMySlider(sender : UISlider){
        
        // Sliderの値に応じてviewの背景のgreen値を変える.
        self.iso = sender.value
        var device: AVCaptureDevice!
        
        //背面カメラの検索
        for d: AnyObject in AVCaptureDevice.devices()
        {
            if d.position == AVCaptureDevicePosition.Back
            {
                device = d as! AVCaptureDevice
                do{
                    try device.lockForConfiguration()
                    device.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: (device.activeFormat.maxISO - device.activeFormat.minISO) * iso + device.activeFormat.minISO, completionHandler: nil)
                    device.unlockForConfiguration()
                }catch{
                    print("無理")
                }
                
            }
        }

    }
}

