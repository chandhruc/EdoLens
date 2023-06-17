//
//  MaskViewController.swift
//  MaskingExample
//
//  Created by CHANDRU on 12/06/23.
//

import UIKit
import Vision
import MobileCoreServices

class MaskViewController: UIViewController {
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var maskedImageView: UIImageView!
    
    // VNRecognizeTextRequest
    lazy private var textRequest: VNRecognizeTextRequest = {
        return configureTextRequestHandler()
    }()
    
    private var maskedImage: UIImage?
    private var isMaskContains: Bool = false
    var scaledImage: UIImage?
    var fileUrl: String?
    var formatType: FormatType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        [errorLabel, maskedImageView, saveButton].forEach({ $0?.isHidden = !isMaskContains })
        if let image = self.scaledImage {
            self.maskedImage = image
            self.processImage(image)
        }
    }

    private func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([self.textRequest])
        } catch {
            print(error)
        }
    }
    
    private func configureTextRequestHandler() -> VNRecognizeTextRequest {
        let textRequest = VNRecognizeTextRequest(completionHandler: { [weak self] request, error in
            
            guard let self = self else { return }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            observations.forEach { observation in
                guard let topCandidate = observation.topCandidates(1).first else { return }
                
                // Recognized String
                let recgonizedText = topCandidate.string
                
                // CornerPoints
                let topLeftPtx = observation.topLeft
                let topRightPtx = observation.topRight
                let bottomLeftPtx = observation.bottomLeft
                let bottomRightPtx = observation.bottomRight
                
                if recgonizedText.aadharValidation() { /// Aadhar
                    self.isMaskContains = true
                    // Get updated points to mask first 8-digits
                    let updatedTopRight = CGPoint(
                        x: topRightPtx.x - ((topRightPtx.x - topLeftPtx.x)/3),
                        y: topRightPtx.y - ((topRightPtx.y - topLeftPtx.y)/3)
                    )
                    let updatedBottomRight = CGPoint(
                        x: bottomRightPtx.x - ((bottomRightPtx.x - bottomLeftPtx.x)/3),
                        y: bottomRightPtx.y - ((bottomRightPtx.y - bottomLeftPtx.y)/3)
                    )
                    
                    self.drawMaskOnImage(withCgpoint: [topLeftPtx, updatedTopRight, updatedBottomRight, bottomLeftPtx])
                    
                } else if recgonizedText.panNumberValidation() { /// PAN
                    self.isMaskContains = true
                    self.drawMaskOnImage(withCgpoint: [topLeftPtx, topRightPtx, bottomRightPtx, bottomLeftPtx])
                }
            }
            
            DispatchQueue.main.async {
                self.errorLabel.isHidden = self.isMaskContains
                [self.maskedImageView, self.saveButton].forEach({ $0?.isHidden =  !self.isMaskContains })
                self.maskedImageView.image = self.maskedImage // Assign MaskedImage to ImageView
            }
        })
        return textRequest
    }
    
    private func drawMaskOnImage(withCgpoint cornerPoints: [CGPoint]) {
        if let maskedImage = self.maskedImage {
            self.maskedImage = drawPointsWithCGraphicImageContext(originalimage: maskedImage, points: cornerPoints)
        }
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        if self.isMaskContains {
            self.saveImageWithFormatType()
        }
    }

    private func saveImageWithFormatType() {
        if let urlString = self.fileUrl, let url = URL(string: urlString) {
            let fileName = url.lastPathComponent
            let imageData = converImageToData()
            self.saveToFileDirectory(imageData: imageData, fileName: fileName)
        } else {
            let imageData = converImageToData()
            self.saveToFileDirectory(imageData: imageData, fileName: "CapturedImage.png")
        }
    }
    
    private func converImageToData() -> Data? {
        var imageData: Data?
        
        switch formatType {
        case .jpg:
            imageData = self.maskedImage?.jpegData(compressionQuality: 1)
            
        case .png:
            imageData = self.maskedImage?.pngData()
            
        case .tiff:
            guard let cgImage = self.maskedImage?.cgImage else {
                return nil
            }
            let tiffData = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(tiffData as CFMutableData, kUTTypeTIFF, 1, nil) else {
                return nil
            }
            let options = [
                kCGImagePropertyTIFFCompression: NSNumber(value: 1),
                kCGImagePropertyTIFFPhotometricInterpretation: NSNumber(value: 2)
            ]
            CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
            CGImageDestinationFinalize(destination)
            imageData = (tiffData as Data)
            
        default: imageData = nil
        }
        
        return imageData
    }
    
    private func saveToFileDirectory(imageData: Data?, fileName: String) {
        if let directoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last {
            do {
                let docUrl = directoryUrl.appendingPathComponent(fileName)
                try imageData?.write(to: docUrl, options: .atomic)
                print("Saved")
            } catch let error {
                print("Save Error", error.localizedDescription)
            }
        }
    }
}

// MARK: - Draw MaskImage with CGPoints using UIGraphicsImageContext
func drawPointsWithCGraphicImageContext(originalimage: UIImage, points normalPoints: [CGPoint]) -> UIImage? {
    let size = originalimage.size
    let scale = originalimage.scale
    
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    defer { UIGraphicsEndImageContext() }
    originalimage.draw(in: CGRect(origin: .zero, size: size))
    UIColor.red.setFill()
    
    // normalized to uikit points
    var uikitPoints = [CGPoint]()
    normalPoints.forEach { ptx in
        let point = CGPoint(x: ptx.x * size.width, y: ptx.y * size.height)
        uikitPoints.append(point)
    }
    
    // Draw path with points
    let beizerPath = UIBezierPath()
    beizerPath.move(to: uikitPoints.first ?? CGPoint.zero)
    uikitPoints.forEach { ptx in
        beizerPath.addLine(to: ptx)
    }
    
    let ctx = UIGraphicsGetCurrentContext()
    ctx?.translateBy(x: 0.0, y: size.height)
    ctx?.scaleBy(x: 1, y: -1)
    ctx?.addPath(beizerPath.cgPath)
    ctx?.drawPath(using: .fill)
    
    return UIGraphicsGetImageFromCurrentImageContext()
}
