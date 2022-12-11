//
//  functions.swift
//  fabr
//
//  Created by Pedro Henrique Cordeiro Soares on 28/07/21.
//

import Foundation

func *(left: String, right: Int) -> String {
    if right <= 0 { return "" }
    if right == 1 { return left}
    return left + left * (right - 1)
}

func printError(_ error: Error?) {
    if let error = error {
        print("\n\("=-" * 15)\n")
        print("Error: \(error.localizedDescription)")
        print("\n\("=-" * 15)\n")
    }
}

func intToTimeString(_ value: Double) -> String {
    let minutes = String(Int(value / 60)).padLeft(2, "0")
    let seconds = String(Int(value) % 60).padLeft(2, "0")
    
    return "\(minutes):\(seconds)"
    
}
