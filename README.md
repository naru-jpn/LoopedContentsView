# LoopedContentsView
[![Swift](https://img.shields.io/badge/swift-2.2-orange.svg?style=flat)](#)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/badge/platform-ios-lightgrey.svg?style=flat)](#)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://opensource.org/licenses/MIT)

## Overview

<img src="https://github.com/naru-jpn/LoopedContentsView/blob/master/LoopedContentsView.gif?raw=true" width="500" />

LoopedContentsView display and handle infinite looped contents. __LoopedContentsView can bear very fast scroll!__

## Usage

### Delegate / DataSource

LoopedContentsView needs delegate and datasource like UITableView/UICollectionView.

#### Delegate

Required
```
func loopedContentsView(loopedContentsView: LoopedContentsView, lengthOfContentAtIndex index: Int) -> CGFloat
```

Optional
```
func loopedContentsView(loopedContentsView: LoopedContentsView, willSelectContentAtIndex index: Int)
func loopedContentsView(loopedContentsView: LoopedContentsView, didSelectContentAtIndex index: Int)
func loopedContentsView(loopedContentsView: LoopedContentsView, willDeselectContentAtIndex index: Int)
func loopedContentsView(loopedContentsView: LoopedContentsView, didDeselectContentAtIndex index: Int)
func loopedContentsView(loopedContentsView: LoopedContentsView, willDisplayCell cell: LoopedContentsViewCell, forItemAtIndex index: Int)
func loopedContentsView(loopedContentsView: LoopedContentsView, didEndDisplaying cell: LoopedContentsViewCell, forItemAtIndex index: Int)
func loopedContentsView(loopedContentsView: LoopedContentsView, didFocusCell cell: LoopedContentsViewCell, forItemAtIndex index: Int)
```

#### DataSource

Required
```
func loopedContentsViewNumberOfContents(loopedContentsView: LoopedContentsView) -> Int
func loopedContentsView(loopedContentsView: LoopedContentsView, cellAtIndex index: Int) -> LoopedContentsViewCell
```

### Register Cell Class

You can register cell class.

```
loopedContentsView.registerClass(class: {Name of Cell Class}.self, forCellReuseIdentifier: "{Identifier}")
```

### Example

[LoopedContentsViewExample](https://github.com/naru-jpn/LoopedContentsView/tree/master/LoopedContentsViewExample)

## License

LoopedContentsView is released under the MIT license. See LICENSE for details.



