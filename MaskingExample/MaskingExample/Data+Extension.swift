//
//  Data+Extension.swift
//  MaskingExample
//
//  Created by CHANDRU on 12/06/23.
//

import Foundation

extension Data {
    var format: String {
        let array = [UInt8](self)
        let ext: String
        switch array[0] {
        case 0xFF:
            ext = "jpg"
        case 0x89:
            ext = "png"
        case 0x49, 0x4D :
            ext = "tiff"
        default:
            ext = "unknown"
        }
        return ext
    }
}
