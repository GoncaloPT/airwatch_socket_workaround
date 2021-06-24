//
//  DataHelpers.swift
//  Runner
//
//  Created by ctw00977-admin on 22/06/2021.
//  From https://github.com/davbeck/MultipartForm
//

import Foundation
extension Data {
    mutating func append(_ string: String) {
        self.append(string.data(using: .utf8, allowLossyConversion: true)!)
    }
}
