//
//  Extensions.swift
//  Photoshare
//
//  Created by Marcus on 2018-10-24.
//  Copyright © 2018 Marcus. All rights reserved.
//

import Foundation




extension Date {
    func isInSameYear(date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .year)
    }

}
