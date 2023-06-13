//
//  VerhoeffAlgorithm.swift
//  EDOLensSDK
//
//  Created by CHANDRU on 16/05/23.
//

final class Verhoeff {
    
    private static let multiplicationTable =
    [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
        [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
        [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
        [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
        [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
        [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
        [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
        [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
        [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
    ]
    
    private static let permutationTable =
    [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
        [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
        [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
        [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
        [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
        [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
        [7, 0, 4, 6, 9, 1, 3, 2, 5, 8]
    ]
    
    private static let inverseTable = [0, 4, 3, 2, 1, 5, 6, 7, 8, 9]
    
    private static func verhoeffDigit(for number: String) -> String {
        var cIndex = 0
        let nums = reversedIntArray(from: number)
        for index in 0..<nums.count {
            cIndex = multiplicationTable[cIndex][permutationTable[((index + 1) % 8)][nums[index]]]
        }
        return String(inverseTable[cIndex])
    }
    
    static func validateVerhoeff(for string: String) -> Bool {
           var cIndex = 0
           let nums = reversedIntArray(from: string)
           for index in 0..<nums.count {
               cIndex = multiplicationTable[cIndex][permutationTable[(index % 8)][nums[index]]]
           }
           return (cIndex == 0)
       }
    
    private static func reversedIntArray(from string: String) -> [Int] {
        var intArray = [Int]()
        for elem in string {
            guard let intValue = Int(String(elem)) else {
                fatalError("Invalid input")
            }
            intArray.append(intValue)
        }
        let reversed = Array(intArray.reversed())
        return reversed
    }
}
