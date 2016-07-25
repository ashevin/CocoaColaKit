//
//  TileViewLayout.swift
//  TileView
//
//  Created by Avi Shevin on 21/07/2016.
//  Copyright © 2016 Rounds. All rights reserved.
//

import UIKit

/**
 Layout strategy for a TileView.
 */
public enum TileViewLayoutType {
    /// Tiles fill from right to left.  When the TileView's maximumColumns is reached, a new row is started.
    case leftThenDown

    /// Tiles fill from left to right.  When the TileView's maximumColumns is reached, a new row is started.
    case rightThenDown

    /// Tiles fill down.  When the TileView's maximumRows is reached, a new column is started to the right of the last column.
    case downThenRight

    /// Tiles fill down.  When the TileView's maximumRows is reached, a new column is started to the left of the last column.
    case downThenLeft
}

public class TileViewLayout {

    let maximumRows: Int
    let maximumColumns: Int
    weak var tileView: TileView!

    private var sizeConstraints: Dictionary<UIView, [NSLayoutConstraint]> = [:]
    private var positionConstraints: Dictionary<UIView, [NSLayoutConstraint]> = [:]

    internal init(maximumRows: Int = 1, maximumColumns: Int = 1) {
        self.maximumRows = maximumRows
        self.maximumColumns = maximumColumns
    }

    internal func replaceTile(_ tile: UIView, with view: UIView, animated: Bool) {
        sizeConstraints[view] = sizeConstraints[tile]!.map({ (constraint) -> NSLayoutConstraint in
            return constraint.adjustedConstraint(firstItem: view)
        })

        positionConstraints[view] = positionConstraints[tile]!.map({ (constraint) -> NSLayoutConstraint in
            return constraint.firstItem as! NSObject == tile ? constraint.adjustedConstraint(firstItem: view) : constraint
        })

        tileView.removeConstraints(sizeConstraints[tile]!)
        tileView.removeConstraints(positionConstraints[tile]!)

        sizeConstraints[tile] = nil
        positionConstraints[tile] = nil

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut,
                           animations: { self.tileView.setNeedsLayout() }, completion: nil)
        }
        else {
            tileView.setNeedsLayout()
        }
    }

    internal func clearContraints(_ tile: UIView) {
        sizeConstraints[tile] = nil
    }

    internal func addSizeConstraints(_ tile: UIView) {
        let constraints = [
            NSLayoutConstraint(item: tile, attribute: .width, relatedBy: .equal,
                               toItem: tileView, attribute: .width, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: tile, attribute: .height, relatedBy: .equal,
                               toItem: tileView, attribute: .height, multiplier: 1.0, constant: 0.0),
            ]

        constraints[0].priority = 999
        constraints[1].priority = 999

        sizeConstraints[tile] = constraints

        tileView.addConstraints(constraints)
    }

    internal func adjustConstraints(animated: Bool) {
        let animationBlock = {
            self.tileView.tiles.forEach({ (tile) in
                self.adjustSizeConstraints(tile, at: self.tileView.tiles.index(of: tile)!)
                self.adjustPositionConstraints(tile)
            })

            self.tileView.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: animationBlock, completion: nil)
        }
        else {
            animationBlock()
        }
    }

    private func adjustSizeConstraints(_ tile: UIView, at: Int) {
        let (row, column) = position(ofIndex: at)

        let constraints = [
            sizeConstraints[tile]![0]
                .adjustedConstraint(multiplier: multiplierForWidthConstraint(row: row)),
            sizeConstraints[tile]![1]
                .adjustedConstraint(multiplier: multiplierForHeightConstraint(column: column))
        ]

        tileView.removeConstraints(sizeConstraints[tile]!)

        sizeConstraints[tile] = constraints

        tileView.addConstraints(sizeConstraints[tile]!)
    }

    private func adjustPositionConstraints(_ tile: UIView) {
        if let constraints = positionConstraints[tile] {
            tileView.removeConstraints(constraints)
        }

        let (secondItemTop, secondItemAttributeTop) = secondItemAndAttributeForTopConstraint(tile)
        let (secondItemLeft, secondItemAttributeLeft) = secondItemAndAttributeForLeftConstraint(tile)

        positionConstraints[tile] = [
            NSLayoutConstraint(item: tile, attribute: .top, relatedBy: .equal,
                               toItem: secondItemTop, attribute: secondItemAttributeTop,
                               multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: tile, attribute: .left, relatedBy: .equal,
                               toItem: secondItemLeft, attribute: secondItemAttributeLeft,
                               multiplier: 1.0, constant: 0.0)
        ]

        tileView.addConstraints(positionConstraints[tile]!)
    }

    private func secondItemAndAttributeForTopConstraint(_ tile: UIView) -> (UIView, NSLayoutAttribute) {
        let (row, column) = position(ofIndex: tileView.tiles.index(of: tile)!)

        let index: Int? = row == 0 ? nil : secondItemIndexForTopConstraint(row: row, column: column)
        let view = index == nil ? tileView : tileView.tiles[index!]
        let attribute: NSLayoutAttribute = row == 0 ? .top : .bottom

        return (view, attribute)
    }

    private func secondItemAndAttributeForLeftConstraint(_ tile: UIView) -> (UIView, NSLayoutAttribute) {
        let (index, attribute) = secondIndexAndAttributeForLeftConstraint(tile)
        let view = index == nil ? tileView : tileView.tiles[index!]

        return (view, attribute)
    }

    private func numberOfRows() -> Int {
        let rows = tileView.tiles.count / maximumColumns

        return rows + (rows * maximumColumns < tileView.tiles.count ? 1 : 0)
    }

    private func numberOfColumns(count: Int) -> Int {
        let columns = count / maximumRows

        return columns + (columns * maximumRows < count ? 1 : 0)
    }

    private func numberOfColumnsForRow(_ row: Int) -> Int {
        return min(maximumColumns, tileView.tiles.count - (row * maximumColumns))
    }

    private func numberOfRowsForColumn(_ column: Int) -> Int {
        return min(maximumRows, tileView.tiles.count - (column * maximumRows))
    }

    internal func positionForAnimation(_ tile: UIView) {
        fatalError("This method must be implemented")
    }

    private func position(ofIndex: Int) -> (Int, Int) {
        fatalError("This method must be implemented")
    }

    private func secondItemIndexForTopConstraint(row: Int, column: Int) -> Int {
        fatalError("This method must be implemented")
    }

    private func secondIndexAndAttributeForLeftConstraint(_ tile: UIView) -> (Int?, NSLayoutAttribute) {
        fatalError("This method must be implemented")
    }

    private func multiplierForWidthConstraint(row: Int) -> CGFloat {
        fatalError("This method must be implemented")
    }

    private func multiplierForHeightConstraint(column: Int) -> CGFloat {
        fatalError("This method must be implemented")
    }

}

public class TileViewLayoutLeftThenDown: TileViewLayout {

    internal override func position(ofIndex: Int) -> (Int, Int) {
        let row: Int = {
            var row = 0
            var index = ofIndex
            while (index >= maximumColumns) {
                row += 1
                index -= maximumColumns
            }

            return row
        }()

        return (row, ofIndex - (row * maximumColumns))
    }

    internal override func positionForAnimation(_ tile: UIView) {
        let (row, _) = position(ofIndex: tileView.tiles.index(of: tile)!)

        if row > 0 {
            tile.frame.origin.y = tile.superview!.bounds.size.height
        }
    }

    private override func secondItemIndexForTopConstraint(row: Int, column: Int) -> Int {
        return (row - 1) * maximumColumns + column
    }

    internal override func secondIndexAndAttributeForLeftConstraint(_ tile: UIView) ->
        (Int?, NSLayoutAttribute) {
            let (row, column) = position(ofIndex: tileView.tiles.index(of: tile)!)

            if column + 1 >= numberOfColumnsForRow(row) {
                return (nil, .left)
            }
            else {
                return (row * maximumColumns + column + 1, .right)
            }
    }

    internal override func multiplierForWidthConstraint(row: Int) -> CGFloat {
        return 1.0 / CGFloat(numberOfColumnsForRow(row))
    }

    internal override func multiplierForHeightConstraint(column: Int) -> CGFloat {
        return 1.0 / CGFloat(numberOfRows())
    }

}

public class TileViewLayoutRightThenDown: TileViewLayout {

    internal override func position(ofIndex: Int) -> (Int, Int) {
        let row: Int = {
            var row = 0
            var index = ofIndex
            while (index >= maximumColumns) {
                row += 1
                index -= maximumColumns
            }

            return row
        }()

        return (row, ofIndex - (row * maximumColumns))
    }

    internal override func positionForAnimation(_ tile: UIView) {
        let (row, _) = position(ofIndex: tileView.tiles.index(of: tile)!)

        tile.frame.origin.x = tile.superview!.bounds.size.width

        if row > 0 {
            tile.frame.origin.y = tile.superview!.bounds.size.height
        }
    }

    private override func secondItemIndexForTopConstraint(row: Int, column: Int) -> Int {
        return (row - 1) * maximumColumns + column
    }

    internal override func secondIndexAndAttributeForLeftConstraint(_ tile: UIView) ->
        (Int?, NSLayoutAttribute) {
            let (row, column) = position(ofIndex: tileView.tiles.index(of: tile)!)

            if column == 0 {
                return (nil, .left)
            }
            else {
                return (row * maximumColumns + column - 1, .right)
            }
    }

    internal override func multiplierForWidthConstraint(row: Int) -> CGFloat {
        return 1.0 / CGFloat(numberOfColumnsForRow(row))
    }

    internal override func multiplierForHeightConstraint(column: Int) -> CGFloat {
        return 1.0 / CGFloat(numberOfRows())
    }

}

public class TileViewLayoutDownThenRight: TileViewLayout {

    internal override func position(ofIndex: Int) -> (Int, Int) {
        let column: Int = {
            var column = 0
            var index = ofIndex
            while (index >= maximumRows) {
                column += 1
                index -= maximumRows
            }

            return column
        }()

        return (ofIndex - (column * maximumRows), column)
    }

    internal override func positionForAnimation(_ tile: UIView) {
        let (_, column) = position(ofIndex: tileView.tiles.index(of: tile)!)

        tile.frame.origin.y = tile.superview!.bounds.size.height

        if column > 0 {
            tile.frame.origin.x = tile.superview!.bounds.size.width
        }
    }

    private override func secondItemIndexForTopConstraint(row: Int, column: Int) -> Int {
        return column * maximumRows + row - 1
    }

    internal override func secondIndexAndAttributeForLeftConstraint(_ tile: UIView) ->
        (Int?, NSLayoutAttribute) {
            let (_, column) = position(ofIndex: tileView.tiles.index(of: tile)!)

            if column == 0 {
                return (nil, .left)
            }
            else {
                return ((column - 1) * maximumRows, .right)
            }
    }

    internal override func multiplierForWidthConstraint(row: Int) -> CGFloat {
        return 1.0 / CGFloat(numberOfColumns(count: tileView.tiles.count))
    }

    internal override func multiplierForHeightConstraint(column: Int) -> CGFloat {
        return 1.0 / CGFloat(numberOfRowsForColumn(column))
    }

}

public class TileViewLayoutDownThenLeft: TileViewLayout {

    internal override func position(ofIndex: Int) -> (Int, Int) {
        let column: Int = {
            var column = 0
            var index = ofIndex
            while (index >= maximumRows) {
                column += 1
                index -= maximumRows
            }

            return column
        }()

        return (ofIndex - (column * maximumRows), column)
    }

    internal override func positionForAnimation(_ tile: UIView) {
        let (row, _) = position(ofIndex: tileView.tiles.index(of: tile)!)

        if row > 0 {
            tile.frame.origin.y = tile.superview!.bounds.size.height
        }
    }

    private override func secondItemIndexForTopConstraint(row: Int, column: Int) -> Int {
        return column * maximumRows + row - 1
    }

    internal override func secondIndexAndAttributeForLeftConstraint(_ tile: UIView) ->
        (Int?, NSLayoutAttribute) {
            let (_, column) = position(ofIndex: tileView.tiles.index(of: tile)!)

            if column + 1 == numberOfColumns(count: tileView.tiles.count) {
                return (nil, .left)
            }
            else {
                return ((column + 1) * maximumRows, .right)
            }
    }
    
    internal override func multiplierForWidthConstraint(row: Int) -> CGFloat {
        return 1.0 / CGFloat(numberOfColumns(count: tileView.tiles.count))
    }
    
    internal override func multiplierForHeightConstraint(column: Int) -> CGFloat {
        return 1.0 / CGFloat(numberOfRowsForColumn(column))
    }
    
}
