//
//  LoopedContentsViewCell.swift
//  InfiniteScrollView
//
//  Created by naru on 2016/07/15.
//  Copyright © 2016年 naru. All rights reserved.
//

import UIKit

public class LoopedContentsViewCell: UIView {
    
    // MARK: Constants
    
    public enum State: Int {
        case none
        case selected
    }
    
    private struct Constants {
        static let DefaultSelectedColor: UIColor = UIColor(white: 0.9, alpha: 1.0)
    }
    
    // MARK: Life Cycle
    
    public required convenience init() {
        self.init(frame: UIScreen.mainScreen().bounds)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColors[.selected] = Constants.DefaultSelectedColor
        
        self.addSubview(self.contentView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Elements
    
    public var index: Int = 0
    
    public var itemIndex: Int = 0
    
    private(set) var selected: Bool = false
    
    public lazy var contentView: UIView = {
        let view: UIView = UIView(frame: self.bounds)
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        return view
    }()
    
    private var backgroundColors: [State: UIColor] = [:]
    
    private var state: State {
        if self.selected {
            return .selected
        } else {
            return .none
        }
    }
    
    // MARK: Control
    
    private func updateBackgroundColor(animated: Bool) {
        
        let color: CGColor? = self.backgroundColors[self.state]?.CGColor
        if animated {
            UIView.animateWithDuration(0.2, animations: {
                self.layer.backgroundColor = color
            })
        } else {
            self.layer.backgroundColor = color
        }
    }
    
    public func setBackgroundColor(backgroundColor: UIColor, forState state: State) {
        
        self.backgroundColors[state] = backgroundColor
        if self.state == state {
            self.updateBackgroundColor(false)
        }
    }
    
    public func setSelected(selected: Bool, animated: Bool) -> Void {

        self.selected = selected
        self.updateBackgroundColor(animated)
    }

}
