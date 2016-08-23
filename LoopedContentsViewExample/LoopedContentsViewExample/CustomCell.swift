//
//  CustomCell.swift
//  LoopedContentsViewExample
//
//  Created by naru on 2016/08/23.
//  Copyright © 2016年 naru. All rights reserved.
//

import UIKit

public class CustomCell: LoopedContentsViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.label)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public lazy var label: UILabel = {
        let bounds: CGRect = self.contentView.bounds
        let origin: CGPoint = CGPoint(x: 1.0, y: 1.0)
        let size: CGSize = CGSize(width: bounds.size.width - 2.0, height: bounds.size.height - 2.0)
        let frame: CGRect = CGRect(origin: origin, size: size)
        let label: UILabel = UILabel(frame: frame)
        label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        label.textColor = UIColor.whiteColor()
        label.font = UIFont(name: "HelveticaNeue-UltraLight", size: 46.0)
        label.textAlignment = .Center
        return label
    }()
}
