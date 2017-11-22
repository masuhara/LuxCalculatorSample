//
//  ViewController.swift
//  LuxCameraSample
//
//  Created by Masuhara on 2017/11/01.
//  Copyright © 2017年 Ylab, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var session: AVCaptureSession!
    
    @IBOutlet var imageView: UIImageView!
    
    // F値
    @IBOutlet var fNumberLabel: UILabel!
    
    // シャッタースピード
    @IBOutlet var exposureTimeLabel: UILabel!
    
    // ISO値
    @IBOutlet var iSOSpeedRatingsLabel: UILabel!
    
    @IBOutlet var fNumberSlider: UISlider!
    @IBOutlet var exposureTimeSlider: UISlider!
    @IBOutlet var iSOSpeedRatingsSlider: UISlider!
    

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setUpCamera()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpCamera() {
        
        let device = AVCaptureDevice.default(for: .video)!
        
        let deviceInput = try? AVCaptureDeviceInput(device: device)
        
        let settings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_32BGRA)]
        
        let dataOutput = AVCaptureVideoDataOutput()
        
        dataOutput.videoSettings = settings as! [String : Any]
        
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)

        session = AVCaptureSession()
        
        session.addInput(deviceInput!)
        
        session.addOutput(dataOutput)
        
        session.sessionPreset = AVCaptureSession.Preset.high

        var videoConnection: AVCaptureConnection? = nil

        session.beginConfiguration()
        
        for connection in dataOutput.connections {
            for port in connection.inputPorts {
                if port.mediaType == AVMediaType.video {
                    videoConnection = connection
                }
            }
        }
        
        if videoConnection?.isVideoOrientationSupported == true {
            videoConnection?.videoOrientation = .portrait
        }
        
        session.commitConfiguration()
        
        session.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        imageView.image = imageFromSampleBufferRef(sampleBuffer: sampleBuffer)
        
        getLux(sampleBuffer: sampleBuffer)
    }
    
    func imageFromSampleBufferRef(sampleBuffer: CMSampleBuffer) -> UIImage {

        let imageBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let baseAddress:UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!
        
        let bytesPerRow:Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width:Int = CVPixelBufferGetWidth(imageBuffer)
        let height:Int = CVPixelBufferGetHeight(imageBuffer)

        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()

        let newContext:CGContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace,  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue)!
        
        let imageRef:CGImage = newContext.makeImage()!
        let resultImage = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.up)
        
        return resultImage
    }
    
    func getLux(sampleBuffer: CMSampleBuffer) {
        //Retrieving EXIF data of camara frame buffer
        let rawMetadata = CMCopyDictionaryOfAttachments(nil, sampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
        let exifData = metadata.value(forKey: "{Exif}") as? NSMutableDictionary
        
        print(exifData)
        
        if let exifData = exifData {
            let fNumber = exifData.value(forKey: "FNumber") as! Double
            let exposureTime = exifData.value(forKey: "ExposureTime") as! Double
            let iSOSpeedRatings = exifData.value(forKey: "ISOSpeedRatings") as! NSArray
            
            fNumberLabel.text = String(fNumber)
            exposureTimeLabel.text = String(exposureTime)
            iSOSpeedRatingsLabel.text = String(iSOSpeedRatings.firstObject as! Double)
        }
        
        let FNumber: Double = exifData?["FNumber"] as! Double
        let ExposureTime: Double = exifData?["ExposureTime"] as! Double
        let ISOSpeedRatingsArray = exifData!["ISOSpeedRatings"] as? NSArray
        let ISOSpeedRatings: Double = ISOSpeedRatingsArray![0] as! Double
        let CalibrationConstant: Double = 50
        
        //Calculating the luminosity
        let luminosity: Double = (CalibrationConstant * FNumber * FNumber ) / ( ExposureTime * ISOSpeedRatings)
        
        print(luminosity)
        
        print(FNumber)
    }


}

