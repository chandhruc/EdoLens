//
//  UIString+Extension.swift
//  MaskingExample
//
//  Created by CHANDRU on 12/06/23.
//

import UIKit
extension String {
    
    // AADHAR
    func aadharValidation() -> Bool {
        let regex = "^[0-9]{1}[0-9]{3}\\s[0-9]{4}\\s[0-9]{4}$"
        let pred = NSPredicate(format: "SELF MATCHES %@", regex)
        guard pred.evaluate(with: self) else {
            return false
        }
        return verhoeffValidate()
    }
    
    // Verhoeff validation
    private func verhoeffValidate() -> Bool {
        let valueJoined = self.components(separatedBy: " ").joined()
        guard  Int(valueJoined) != nil else {
            return false
        }
        let bool = Verhoeff.validateVerhoeff(for: valueJoined)
        return bool
    }
    
    // PAN
    func panNumberValidation() -> Bool {
        let regex = "[A-Z]{5}[0-9]{4}[A-Z]{1}"
        let pred = NSPredicate(format: "SELF MATCHES %@", regex)
        return pred.evaluate(with: self)
    }
}
