//
//  LoopedContentsView.swift
//  LoopedContentsView
//
//  Created by naru on 2016/07/14.
//  Copyright © 2016年 naru. All rights reserved.
//

import UIKit
import Foundation

public protocol LoopedContentsViewDataSource {
    /// Return 
    func loopedContentsViewNumberOfContents(loopedContentsView: LoopedContentsView) -> Int
    func loopedContentsView(loopedContentsView: LoopedContentsView, cellAtIndex index: Int) -> LoopedContentsViewCell
}

public protocol LoopedContentsViewDelegate {
    // Required
    func loopedContentsView(loopedContentsView: LoopedContentsView, lengthOfContentAtIndex index: Int) -> CGFloat
    // Optional
    func loopedContentsView(loopedContentsView: LoopedContentsView, willSelectContentAtIndex index: Int)
    func loopedContentsView(loopedContentsView: LoopedContentsView, didSelectContentAtIndex index: Int)
    func loopedContentsView(loopedContentsView: LoopedContentsView, willDeselectContentAtIndex index: Int)
    func loopedContentsView(loopedContentsView: LoopedContentsView, didDeselectContentAtIndex index: Int)
    func loopedContentsView(loopedContentsView: LoopedContentsView, willDisplayCell cell: LoopedContentsViewCell, forItemAtIndex index: Int)
    func loopedContentsView(loopedContentsView: LoopedContentsView, didEndDisplaying cell: LoopedContentsViewCell, forItemAtIndex index: Int)
    func loopedContentsView(loopedContentsView: LoopedContentsView, didFocusCell cell: LoopedContentsViewCell, forItemAtIndex index: Int)
}

extension LoopedContentsViewDelegate {
    func loopedContentsView(loopedContentsView: LoopedContentsView, willSelectContentAtIndex index: Int) { }
    func loopedContentsView(loopedContentsView: LoopedContentsView, didSelectContentAtIndex index: Int) { }
    func loopedContentsView(loopedContentsView: LoopedContentsView, willDeselectContentAtIndex index: Int) { }
    func loopedContentsView(loopedContentsView: LoopedContentsView, didDeselectContentAtIndex index: Int) { }
    func loopedContentsView(loopedContentsView: LoopedContentsView, willDisplayCell cell: LoopedContentsViewCell, forItemAtIndex index: Int) { }
    func loopedContentsView(loopedContentsView: LoopedContentsView, didEndDisplaying cell: LoopedContentsViewCell, forItemAtIndex index: Int) { }
    func loopedContentsView(loopedContentsView: LoopedContentsView, didFocusCell cell: LoopedContentsViewCell, forItemAtIndex index: Int) { }
}

public class LoopedContentsView: UIView, UIScrollViewDelegate {
    
    // MARK: Constants
    
    public enum Orientation {
        case Horizontal
        case Vertical
    }
    
    private struct Constants {
        
        static let ScrollLength: CGFloat = 1.0E+7
        static let DefaultScrollEndDraggingFactor: CGFloat = 350.0
        static let MaxStoredCellCount: Int = 5
        
        static let Padding: CGFloat = 2.0
        static let DefaultIndicatorColor: UIColor = UIColor(white: 0.3, alpha: 1.0)
    }
    
    // MARK: Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.scrollView)
        self.addSubview(self.horizontalScrollIndicator)
        self.addSubview(self.verticalScrollIndicator)
        
        self.setScrollPosition(0, animated: true)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Element
    
    public var delegate: LoopedContentsViewDelegate? = nil
    
    public var dataSource: LoopedContentsViewDataSource? = nil
    
    public var allowsMultipleSelection: Bool = false
    
    public var pagingEnabled: Bool = true
    
    public var scrollEndDraggingFactor: CGFloat = Constants.DefaultScrollEndDraggingFactor
    
    public var cellTransform: ((range: CGFloat) -> CGAffineTransform)? = nil
    
    public var cellAlpha: ((range: CGFloat) -> CGFloat)? = nil
    
    private var totalItemLength: CGFloat = 0.0
    
    private var numberOfItems: Int = 0
    
    private var lengthOfItems: [CGFloat] = []
    
    private var activeCells: [Int: LoopedContentsViewCell] = [:]
    
    private var reusedClassStore: [String: AnyClass] = [:]
    
    private var reusedCellStore: [String: [LoopedContentsViewCell]] = [:]
    
    private var visibleCellIndexSet: Set<Int> = Set<Int>()
    
    private var selectedItemIndexSet: Set<Int> = Set<Int>()
    
    private var centerItem: (itemIndex: Int, index: Int, origin: CGFloat) = (0, 0, 0.0)
    
    private lazy var scrollView: UIScrollView = {
        let frame: CGRect = self.bounds
        let scrollView: UIScrollView = UIScrollView(frame: frame)
        scrollView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        scrollView.contentSize = self.contentSize
        scrollView.exclusiveTouch = true
        return scrollView
    }()
    
    public lazy var horizontalScrollIndicator: UIView  = {
        let frame: CGRect = CGRect(x: 0.0, y: 0.0, width: 4.0, height: 4.0)
        let view: UIView = UIView(frame: frame)
        view.frame = frame
        view.layer.cornerRadius = 2.0
        view.layer.masksToBounds = true
        view.backgroundColor = Constants.DefaultIndicatorColor
        view.alpha = 0.0
        view.hidden = true
        return view
    }()
    
    public lazy var verticalScrollIndicator: UIView  = {
        let frame: CGRect = CGRect(x: 0.0, y: 0.0, width: 4.0, height: 4.0)
        let view: UIView = UIView(frame: frame)
        view.frame = frame
        view.layer.cornerRadius = 2.0
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.grayColor()
        view.alpha = 0.0
        view.hidden = true
        return view
    }()
    
    // MARK: Access
    
    func next(itemIndex itemIndex: Int) -> Int {
        return itemIndex == self.numberOfItems - 1 ? 0 : itemIndex + 1
    }
    
    func previous(itemIndex itemIndex: Int) -> Int {
        return itemIndex == 0 ? self.numberOfItems - 1 : itemIndex - 1
    }
    
    // MARK: Computed Variable
    
    private var horizontalScrollIndicatorCenter: CGPoint {
        let ratio: CGFloat = self.scrollView.contentOffset.x/(self.scrollView.contentSize.width - self.scrollView.frame.size.width)
        let center: CGPoint = {
            let indicatorSize: CGSize = self.horizontalScrollIndicator.frame.size
            let x: CGFloat = Constants.Padding + indicatorSize.width/2.0 + (self.frame.size.width - Constants.Padding*2 - indicatorSize.width)*ratio
            let y: CGFloat = self.frame.size.height - Constants.Padding - self.horizontalScrollIndicator.frame.size.height/2.0
            return CGPoint(x: x, y: y)
        }()
        return center
    }
    
    private var verticalScrollIndicatorCenter: CGPoint {
        let ratio: CGFloat = self.scrollView.contentOffset.y/(self.scrollView.contentSize.height - self.scrollView.frame.size.height)
        let center: CGPoint = {
            let indicatorSize: CGSize = self.horizontalScrollIndicator.frame.size
            let x: CGFloat = self.frame.size.width - Constants.Padding - self.horizontalScrollIndicator.frame.size.width/2.0
            let y: CGFloat = Constants.Padding + indicatorSize.height/2.0 + (self.frame.size.height - Constants.Padding*2 - indicatorSize.height)*ratio
            return CGPoint(x: x, y: y)
        }()
        return center
    }

    public var selectedIndexSet: Set<Int> {
        return self.selectedItemIndexSet
    }
    
    public var scrollPosition : CGFloat {
        get {
            switch self.orientation {
            case .Horizontal:
                return self.scrollView.contentOffset.x + (self.frame.size.width - Constants.ScrollLength)/2.0
            case .Vertical:
                return self.scrollView.contentOffset.y + self.frame.size.height/2.0 - Constants.ScrollLength/2.0
            }
        }
        set {
            self.setScrollPosition(newValue, animated: false)
        }
    }
    
    public var orientation: Orientation = .Horizontal {
        didSet {
            self.scrollView.contentSize = self.contentSize
            self.horizontalScrollIndicator.alpha = 0.0
            self.verticalScrollIndicator.alpha = 0.0
            self.setScrollPosition(0, animated: true)
        }
    }
    
    private var contentSize: CGSize {
        switch self.orientation {
        case .Horizontal:
            return CGSize(width: Constants.ScrollLength, height: self.frame.height)
        case .Vertical:
            return CGSize(width: self.frame.height, height: Constants.ScrollLength)
        }
    }
    
    private var controlledScrollIndicator: UIView {
        switch self.orientation {
        case .Horizontal:
            return self.horizontalScrollIndicator
        case .Vertical:
            return self.verticalScrollIndicator
        }
    }
    
    override public var frame: CGRect {
        didSet {
            self.updateVisibleCells()
        }
    }
    
    // MARK: Control
    
    public func setScrollPosition(position: CGFloat, animated: Bool) {
        let offset: CGPoint
        switch self.orientation {
        case .Horizontal:
            offset = CGPoint(x: (Constants.ScrollLength - self.frame.size.width)/2.0 + position, y: 0.0)
        case .Vertical:
            offset = CGPoint(x: 0.0, y: (Constants.ScrollLength - self.frame.size.height)/2.0 + position)
        }
        self.scrollView.setContentOffset(offset, animated: animated)
    }
    
    public func selectItem(atIndex index: Int, animated: Bool) {
        
        // Deselect Item if Multiple Selectin is Not Allowed
        if !self.allowsMultipleSelection {
            let deselectedItemIndexSet: [Int] = self.selectedItemIndexSet.filter { _index -> Bool in
                return _index != index
            }
            for _index in deselectedItemIndexSet {
                self.deselectItem(atIndex: _index, animated: animated)
            }
        }
        
        let willSelect: Bool = !self.selectedItemIndexSet.contains(index)
        if !willSelect {
            return
        }
        
        // Call Delegate Method (Will)
        if let delegate: LoopedContentsViewDelegate = self.delegate {
            delegate.loopedContentsView(self, willSelectContentAtIndex: index)
        }
        
        self.selectedItemIndexSet.insert(index)
        
        for (_, cell) in self.activeCells where cell.itemIndex == index {
            cell.setSelected(true, animated: true)
        }
        
        // Call Delegate Method (Did)
        if let delegate: LoopedContentsViewDelegate = self.delegate {
            delegate.loopedContentsView(self, didSelectContentAtIndex: index)
        }
    }
    
    public func deselectItem(atIndex index: Int, animated: Bool) {
        
        let willDeselect: Bool = self.selectedItemIndexSet.contains(index)
        if !willDeselect {
            return
        }
        
        // Call Delegate Method (Will)
        if let delegate: LoopedContentsViewDelegate = self.delegate {
            delegate.loopedContentsView(self, willDeselectContentAtIndex: index)
        }
    
        self.selectedItemIndexSet.remove(index)
        
        for (_, cell) in self.activeCells where cell.itemIndex == index {
            cell.setSelected(false, animated: true)
        }
        
        // Call Delegate Method (Did)
        if let delegate: LoopedContentsViewDelegate = self.delegate {
            delegate.loopedContentsView(self, didDeselectContentAtIndex: index)
        }
    }
    
    private func adjustScrollIndicator() {
        switch self.orientation {
        case .Horizontal:
            self.horizontalScrollIndicator.center = self.horizontalScrollIndicatorCenter
        case .Vertical:
            self.verticalScrollIndicator.center = self.verticalScrollIndicatorCenter
        }
    }
    
    // MARK: Reuse
    
    public func registerClass(class _class: AnyClass, forCellReuseIdentifier identifier: String) {
        self.reusedClassStore[identifier] = _class
    }
    
    public func dequeueReusableCellWithIdentifier(identifier: String) -> LoopedContentsViewCell {
    
        let _class: LoopedContentsViewCell.Type? = self.reusedClassStore[identifier] as? LoopedContentsViewCell.Type
        if _class == nil {
            assertionFailure("Reusable Class is Not Registered for Identifier '\(identifier)'")
        }
        
        let name: String = NSStringFromClass(_class!) as String
        if let cell: LoopedContentsViewCell = self.reusedCellStore[name]?.last {
            // Return Stored Cell
            self.reusedCellStore[name]?.removeLast()
            return cell
        } else {
            // Return New Cell
            let cell: LoopedContentsViewCell = _class!.init()
            return cell
        }
    }
    
    // MARK: Update
    
    public func reloadData() {
        
        self.numberOfItems = self.dataSource?.loopedContentsViewNumberOfContents(self) ?? 0
        self.lengthOfItems = (0..<self.numberOfItems).map { (index: Int) -> CGFloat in
            return self.delegate?.loopedContentsView(self, lengthOfContentAtIndex: index) ?? 0.0
        }
        self.totalItemLength = self.lengthOfItems.reduce(0.0) { $0 + $1 }
        
        self.visibleCellIndexSet = Set<Int>()
        self.activeCells = [:]
        self.reusedCellStore = [:]
        
        self.updateVisibleCells()
    }
    
    private func updateVisibleCells() {
        
        if self.numberOfItems <= 0 {
            return
        }
        guard let dataSource: LoopedContentsViewDataSource = self.dataSource else {
            return
        }
        
        let position: CGFloat = self.scrollPosition + self.lengthOfItems[0]/2.0
        let multiple: Int = {
            let num: Int = Int(position)/Int(self.totalItemLength)
            return position < 0 ? num - 1 : num
        }()
        
        // Get Index and Origin of Center Item
        self.centerItem = {
            var value: CGFloat = position - self.totalItemLength*CGFloat(multiple)
            if value >= 0 {
                for (itemIndex, length) in self.lengthOfItems.enumerate() {
                    if value - length <= 0 {
                        return (itemIndex, itemIndex + self.numberOfItems*multiple, -value)
                    }
                    value = value - length
                }
            } else {
                value = abs(value)
                for (itemIndex, length) in self.lengthOfItems.reverse().enumerate() {
                    value = value - length
                    if value <= 0 {
                        let _itemIndex: Int = self.numberOfItems - itemIndex - 1
                        return (_itemIndex, _itemIndex + self.numberOfItems*multiple, value)
                    }
                }
            }
            return (0, 0, 0.0)
        }()
        
        // Find Visible Next Index
        let nextItemIndexes: [Int] = {
            var indexes: [Int] = []
            var itemIndex: Int = centerItem.itemIndex
            var origin: CGFloat = centerItem.origin + self.lengthOfItems[itemIndex]
            while origin < self.frame.size.width/2.0 {
                itemIndex = self.next(itemIndex: itemIndex)
                origin = origin + self.lengthOfItems[itemIndex]
                indexes.append(itemIndex)
            }
            return indexes
        }()
        
        var origin: CGFloat = centerItem.origin
        
        // Find Visible Previous Index
        let previousItemIndexes: [Int] = {
            var indexes: [Int] = []
            var itemIndex: Int = centerItem.itemIndex
            while origin > -self.frame.size.width/2.0 {
                itemIndex = self.previous(itemIndex: itemIndex)
                origin = origin - self.lengthOfItems[itemIndex]
                indexes.insert(itemIndex, atIndex: 0)
            }
            return indexes
        }()
        
        let itemIndexes: [Int] = previousItemIndexes + [self.centerItem.itemIndex] + nextItemIndexes
        
        // Get Visible Indexes in Whole Scroll View
        let previousIndexes: [Int] = (0..<(previousItemIndexes.count)).enumerate().map { (index: Int, value: Int) -> Int in
            return self.centerItem.index - index - 1
        }.reverse()
        let nextIndexes: [Int] = (0..<(nextItemIndexes.count)).enumerate().map { (index: Int, value: Int) -> Int in
            return self.centerItem.index + index + 1
        }
        
        // Get New/Disable Cell Indexes
        let indexes: [Int] = previousIndexes + [self.centerItem.index] + nextIndexes
        let indexSet: Set<Int> = Set(indexes)
        let newCellIndexSet: Set<Int> = indexSet.subtract(self.visibleCellIndexSet)
        let disableCellIndexSet: Set<Int> = self.visibleCellIndexSet.subtract(indexSet)
        self.visibleCellIndexSet = indexSet
        
        // Convert Origin Value for Scroll View
        origin = {
            switch self.orientation {
            case .Horizontal:
                return origin + self.scrollView.contentOffset.x + self.frame.size.width/2.0
            case .Vertical:
                return origin + self.scrollView.contentOffset.y + self.frame.size.height/2.0
            }
        }()
        
        // Get Cell Frames
        let frames: [CGRect] = {
            var frames: [CGRect] = []
            for index in itemIndexes {
                let frame: CGRect
                switch self.orientation {
                case .Horizontal:
                    frame = CGRect(x: origin, y: 0.0, width: self.lengthOfItems[index], height: self.frame.size.height)
                case .Vertical:
                    frame = CGRect(x: 0.0, y: origin, width: self.frame.size.width, height: self.lengthOfItems[index])
                }
                frames.append(frame)
                origin = origin + self.lengthOfItems[index]
            }
            return frames
        }()
        
        // Update Cell Frame
        for (_index, itemIndex) in itemIndexes.enumerate() {
                        
            let index: Int = indexes[_index]
            let frame: CGRect = frames[_index]
        
            // Create New Cells
            if newCellIndexSet.contains(index) {
                
                let cell: LoopedContentsViewCell = dataSource.loopedContentsView(self, cellAtIndex: itemIndex)
                self.activeCells[index] = cell
                cell.frame = frame
                cell.index = index
                cell.itemIndex = itemIndex
                
                let selected: Bool = self.selectedItemIndexSet.contains(cell.itemIndex)
                cell.setSelected(selected, animated: false)
                
                let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onCellTapped(_:)))
                cell.addGestureRecognizer(tapGestureRecognizer)
                
                // Cell Will Display
                if let delegate: LoopedContentsViewDelegate = self.delegate {
                    delegate.loopedContentsView(self, willDisplayCell: cell, forItemAtIndex: itemIndex)
                }
                
                self.scrollView.addSubview(cell)
            }
        }
        
        // Remove Disabled Cells
        for index in disableCellIndexSet {
            if let cell = self.activeCells[index] {
                
                cell.removeFromSuperview()
                self.activeCells[index] = nil
                
                // Cell Did End Displaying
                if let delegate: LoopedContentsViewDelegate = self.delegate {
                    delegate.loopedContentsView(self, didEndDisplaying: cell, forItemAtIndex: cell.itemIndex)
                }
                
                // Cell is Not Cached if Any Reusable Cell Class is Not Registered.
                if self.reusedClassStore.keys.count == 0 {
                    continue
                }

                // Store Reusable Cell
                let name: String = NSStringFromClass(cell.dynamicType) as String
                
                var cells: [LoopedContentsViewCell] = []
                if let storedCells: [LoopedContentsViewCell] = self.reusedCellStore[name] {
                    cells = cells + storedCells
                }
                if cells.count < Constants.MaxStoredCellCount {
                    cells.append(cell)
                    self.reusedCellStore[name] = cells
                }
            }
        }
        
        // Update Cell Transform, Alpha
        if self.cellTransform != nil || self.cellAlpha != nil {
            
            for (_, cell) in self.activeCells {
                
                let range: CGFloat = {
                    switch self.orientation {
                    case .Horizontal:
                        return CGRectGetMidX(cell.frame) - self.scrollView.contentOffset.x - self.scrollView.frame.size.width/2.0
                    case .Vertical:
                        return CGRectGetMidY(cell.frame) - self.scrollView.contentOffset.y - self.scrollView.frame.size.height/2.0
                    }
                }()
                
                if let cellTransform: ((range: CGFloat) -> CGAffineTransform) = self.cellTransform {
                    cell.contentView.transform = cellTransform(range: range)
                }
                if let cellAlpha: ((range: CGFloat) -> CGFloat) = self.cellAlpha {
                    cell.contentView.alpha = cellAlpha(range: range)
                }
                
            }
        }
    }
    
    // MARK: Gesture
    
    func onCellTapped(sender: UITapGestureRecognizer) {
        
        guard let cell: LoopedContentsViewCell = sender.view as? LoopedContentsViewCell else {
            return
        }
        
        let itemIndex: Int = cell.itemIndex
        let willSelect: Bool = !self.selectedItemIndexSet.contains(itemIndex)
        if willSelect {
            self.selectItem(atIndex: itemIndex, animated: true)
        } else {
            self.deselectItem(atIndex: itemIndex, animated: true)
        }
    }
    
    // MARK: Scroll View Delegate
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        
        self.adjustScrollIndicator()
        self.updateVisibleCells()
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
        self.adjustScrollIndicator()
        self.controlledScrollIndicator.alpha = 1.0
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        // Cell Did Focus
        if let delegate: LoopedContentsViewDelegate = self.delegate, cell: LoopedContentsViewCell = self.activeCells[self.centerItem.index] {
            delegate.loopedContentsView(self, didFocusCell: cell, forItemAtIndex: centerItem.itemIndex)
        }
        
        UIView.animateWithDuration(0.2, animations: {
            self.controlledScrollIndicator.alpha = 0.0
        })
    }
    
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if !self.pagingEnabled {
            return
        }
        
        switch self.orientation {
        case .Horizontal:
            
            let middle: CGFloat = self.scrollView.contentOffset.x + self.frame.size.width/2.0
            let target: CGFloat = middle + self.centerItem.origin + self.scrollEndDraggingFactor*velocity.x
            var current: (index: Int, x: CGFloat) = (index: self.centerItem.itemIndex, x: middle + self.centerItem.origin)
            
            if velocity.x >= 0.0 {
                while true {
                    let nextLength: CGFloat = self.lengthOfItems[self.next(itemIndex: current.index)]
                    if current.x + nextLength >= target {
                        targetContentOffset.memory.x = current.x + nextLength/2.0 - self.frame.size.width/2.0
                        return
                    }
                    current.index = self.next(itemIndex: current.index)
                    current.x = current.x + nextLength
                }
            } else {
                while true {
                    let previousLength: CGFloat = self.lengthOfItems[self.previous(itemIndex: current.index)]
                    if current.x - previousLength <= target {
                        targetContentOffset.memory.x = current.x + previousLength/2.0 - self.frame.size.width/2.0
                        return
                    }
                    current.index = self.previous(itemIndex: current.index)
                    current.x = current.x - previousLength
                }
            }
        case .Vertical:
            
            let middle: CGFloat = self.scrollView.contentOffset.y + self.frame.size.height/2.0
            let target: CGFloat = middle + self.centerItem.origin + self.scrollEndDraggingFactor*velocity.y
            var current: (index: Int, y: CGFloat) = (index: self.centerItem.itemIndex, y: middle + self.centerItem.origin)
            
            if velocity.y >= 0.0 {
                while true {
                    let nextLength: CGFloat = self.lengthOfItems[self.next(itemIndex: current.index)]
                    if current.y + nextLength >= target {
                        targetContentOffset.memory.y = current.y + nextLength/2.0 - self.frame.size.height/2.0
                        return
                    }
                    current.index = self.next(itemIndex: current.index)
                    current.y = current.y + nextLength
                }
            } else {
                while true {
                    let previousLength: CGFloat = self.lengthOfItems[self.previous(itemIndex: current.index)]
                    if current.y - previousLength <= target {
                        targetContentOffset.memory.y = current.y + previousLength/2.0 - self.frame.size.height/2.0
                        return
                    }
                    current.index = self.previous(itemIndex: current.index)
                    current.y = current.y - previousLength
                }
            }
        }
    }
}
