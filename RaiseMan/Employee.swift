//
//  Employee.swift
//  RaiseMan
//
//  Created by Stephen Skubik-Peplaski on 9/17/15.
//  Copyright © 2015 Stephen Skubik-Peplaski. All rights reserved.
//

import Foundation

class Employee: NSObject {
    var name: String? = "New Employee"
    var raise: Float = 0.05
    
    func validateRaise(raiseNumberPointer: AutoreleasingUnsafeMutablePointer<NSNumber?>) throws {
            let raiseNumber = raiseNumberPointer.memory
            if raiseNumber == nil {
                let domain = "UserInputValidationErrorDomain"
                let code = 0
                let userInfo = [NSLocalizedDescriptionKey : "An employee's raise must be a number."]
                throw NSError(domain: domain, code: code, userInfo: userInfo)
            }
    }
}