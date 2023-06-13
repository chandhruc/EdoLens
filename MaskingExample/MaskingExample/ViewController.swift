//
//  ViewController.swift
//  MaskingExample
//
//  Created by CHANDRU on 12/06/23.
//

import UIKit
import MobileCoreServices

class ViewController: UIViewController {

    lazy private var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.mediaTypes = [kUTTypeImage as String]
        picker.modalPresentationStyle = .fullScreen
        return picker
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func capturePhoto(_ sender: Any) {
        self.imagePicker.sourceType = .camera
        self.present(self.imagePicker, animated: true)
    }
    
    @IBAction func photoLibrary(_ sender: Any) {
        self.imagePicker.sourceType = .photoLibrary
        self.present(self.imagePicker, animated: true)
    }
    
    private func moveToMaskController(with image: UIImage) {
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "MaskViewController") as? MaskViewController {
            controller.modalPresentationStyle = .fullScreen
            controller.scaledImage = image
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            if let imageUrl = info[.imageURL] as? URL,
                let imgData = try? Data(contentsOf: imageUrl) {
                
                // Process Picked Image if PNG, JPG & TIFF type
                guard imgData.format != "unknown", let img = UIImage(data: imgData), let resizedImg = img.scaledImage(with: img.size) else {
                    return
                }
                self.moveToMaskController(with: resizedImg)
                
            } else if let captureImage = info[.originalImage] as? UIImage,
                      let resizedImg = captureImage.scaledCaptureImage(with: captureImage.size) { // Process Captured Photo
                
                self.moveToMaskController(with: resizedImg)
            }
        }
    }
}
