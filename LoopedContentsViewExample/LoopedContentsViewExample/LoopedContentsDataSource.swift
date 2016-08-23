//
//  LoopedContentsDataSource.swift
//  LoopedContentsViewExample
//
//  Created by naru on 2016/08/23.
//  Copyright © 2016年 naru. All rights reserved.
//

import UIKit

public class LoopedContentsDataSource: LoopedContentsViewDataSource {

    // MARK: Constants
    
    public struct Constants {
        static let Contents: [String] = (0...20).map { (element: Int) -> String in return "\(element)" }
    }
    
    public func loopedContentsViewNumberOfContents(loopedContentsView: LoopedContentsView) -> Int {
        return Constants.Contents.count
    }
    
    public func loopedContentsView(loopedContentsView: LoopedContentsView, cellAtIndex index: Int) -> LoopedContentsViewCell {
        let cell = loopedContentsView.dequeueReusableCellWithIdentifier("cell") as! CustomCell
        self.configulerCell(cell, atIndex: index)
        return cell
    }
    
    private func configulerCell(cell: CustomCell, atIndex index: Int) {
        
        let color: UIColor = {
            let red: CGFloat = CGFloat(Constants.Contents.count - index - 1)/CGFloat(Constants.Contents.count - 1)
            let blue: CGFloat = CGFloat(index)/CGFloat(Constants.Contents.count - 1)
            return UIColor(red: red, green: 0.0, blue: blue, alpha: 1.0)
        }()
        cell.label.backgroundColor = color
        
        cell.label.text = Constants.Contents[index]
    }
}
