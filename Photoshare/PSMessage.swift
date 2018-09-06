//
//  PSMessage.swift
//  Photoshare
//
//  Created by Marcus on 2018-08-16.
//  Copyright © 2018 Marcus. All rights reserved.
//

import Foundation

struct PSMessage{
    
    private var endian: String
    private var version: Int
    private var instruction: Int
    private var length: Int
    private var data: String
    
    init(endian: String, version: Int, instruction: Int, length: Int, data: String){
        self.endian = endian
        self.version = version
        self.instruction = instruction
        self.length = length
        self.data = data
    }
    
    init(fromString string: String){
        endian = string[0..<1]
        version = Int(string[1..<3])!
        instruction = Int(string[3..<5])!
        length = Int(string[5..<7])!
        data = string[7..<string.count]
    }
    
    public func getString() -> String{
        
        let msg = "\(endian)\(formatInt(with: version))\(formatInt(with: instruction))\(formatInt(with: length))\(data)"
        return msg
    }
    
    public func getData() -> String{
        return data
    }
    
    private func formatInt(with int: Int) -> String{
        return String(format: "%02d", int)
    }
    
    public func isError() -> Bool{
        if instruction == 99{
            return true
        } else {
            return false
        }
    }
    
}


extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[idx1..<idx2])
    }
}
