//
//  SelectContentDelegate.swift
//  IntelRacing
//
//  Created by Michael Wu on 9/26/21.
//

import Foundation
protocol SelectContentDelegate:AnyObject {
    func onContentSelectionMade(filePath: String, name:String)
    func onContentSelectionCanceled()
}
