//
//  MaskViewController.swift
//  MaskingExample
//
//  Created by CHANDRU on 12/06/23.
//

import UIKit
import Vision

class MaskViewController: UIViewController {

    @IBOutlet weak var maskedImageView: UIImageView!

    // VNRecognizeTextRequest
    lazy private var textRequest: VNRecognizeTextRequest = {
        return configureTextRequestHandler()
    }()
    
    private var maskedImage: UIImage?
    var scaledImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
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
                   self.drawMaskOnImage(withCgpoint: [topLeftPtx, topRightPtx, bottomRightPtx, bottomLeftPtx])
                }
            }
            
            DispatchQueue.main.async {
                self.maskedImageView.image = self.maskedImage // Assign MaskedImage to ImageView
            }
        })
        return textRequest
    }
    
    private func drawMaskOnImage(withCgpoint cornerPoints: [CGPoint]) {
        if let maskedImage = self.maskedImage {
            self.maskedImage = drawPointsWithGraphicsRender(originalimage: maskedImage, points: cornerPoints)
        }
    }
}

// MARK: - Draw MaskImage with CGPoints using UIGraphicsRender
func drawPointsWithGraphicsRender(originalimage: UIImage, points normalPoints: [CGPoint]) -> UIImage? {
    let size = originalimage.size
    let image = UIGraphicsImageRenderer(size: size).image { ctx in
        originalimage.draw(at: .zero)
        
        // Define color
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
        
        ctx.cgContext.translateBy(x: 0.0, y: size.height)
        ctx.cgContext.scaleBy(x: 1, y: -1)
        
        ctx.cgContext.addPath(beizerPath.cgPath)
        ctx.cgContext.drawPath(using: .fill)
    }
    return image
}
