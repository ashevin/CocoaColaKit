//
//  TileViewLayout.swift
//  TileView
//
//  Created by Avi Shevin on 21/07/2016.
//  Copyright © 2016 Rounds. All rights reserved.
//

import UIKit

/**
 Alignment for tiles as they are added to the TileView.
 */
public enum RowAlignment {
    /// Tiles are added right to left.
    case right

    /// Tiles are added left to right.
    case left

    /// Alignment is determined by the device's RTL settings.
    case auto
}

/**
 Determines how otherwise-empty space is filled.
 */
public enum FillDirection {
    /// Tiles on a partially filled row will expand to fill the width of the TileView.
    case horizontal

    /// Tiles in a partially filled column will expand to fill the height of the TileView.
    case vertical
}

internal class TileViewLayout {

    let maximumRows: Int
    let maximumColumns: Int
    let alignment: RowAlignment
    let fillDirection: FillDirection
    weak var tileView: TileView!

    private var sizeConstraints: Dictionary<Tile, [NSLayoutConstraint]> = [:]
    private var positionConstraints: Dictionary<Tile, [NSLayoutConstraint]> = [:]
    private var sizeAdjustments: Dictionary<Tile, (CGFloat, CGFloat)> = [:]

    //MARK: Public API

    internal init(maximumRows: Int = 1, maximumColumns: Int = 1, alignment: RowAlignment, fillDirection: FillDirection) {
        self.maximumRows = maximumRows
        self.maximumColumns = maximumColumns
        self.alignment = alignment
        self.fillDirection = fillDirection
    }

    internal func replaceTile(_ tile: Tile, with view: Tile, animated: Bool) {
        let tileSizeContraints: [NSLayoutConstraint] = sizeConstraints[tile]!
        sizeConstraints[view] = tileSizeContraints.map({ (constraint) -> NSLayoutConstraint in
            return constraint.adjustedConstraint(view)
        })

        let tilePositionContraints: [NSLayoutConstraint] = positionConstraints[tile]!
        positionConstraints[view] = tilePositionContraints.map({ (constraint) -> NSLayoutConstraint in
            return constraint.firstItem as! NSObject == tile ? constraint.adjustedConstraint(view) : constraint
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

    internal func placeTileForAnimatedReplacement(_ tile: Tile, placeholder: Tile) {
        tile.frame = placeholder.frame

        let leftEdge = tile.frame.minX == 0
        let rightEdge = tile.frame.maxX == tile.superview?.bounds.maxX

        if leftEdge && rightEdge {
            tile.frame.origin.y -= tile.frame.height
        }
        else if leftEdge {
            tile.frame.origin.x -= tile.frame.width
        }
        else if rightEdge {
            tile.frame.origin.x = tile.frame.maxX
        }
        else {
            tile.frame.origin.y -= tile.frame.height
        }

        tile.layoutIfNeeded()
    }

    internal func clearPositionInformation(_ tile: Tile) {
        sizeConstraints[tile] = nil
        positionConstraints[tile] = nil
        sizeAdjustments[tile] = nil
    }

    internal func clearSizeAdjustments() {
        sizeAdjustments.removeAll()
    }

    internal func addSizeConstraints(_ tile: Tile) {
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

    internal func adjustTile(_ tile: Tile, widthBy width: CGFloat = 0.0, heightBy height: CGFloat = 0.0) {
        let currentAdjustment = sizeAdjustments[tile]

        let currentWidth = currentAdjustment?.0 ?? 0.0
        let currentHeight = currentAdjustment?.1 ?? 0.0

        sizeAdjustments[tile] = (currentWidth + width, currentHeight + height)

        layout(inView: tileView, tiles: tileView.tiles, animated: false)
    }

    internal func layout(inView view: UIView, tiles: [Tile], animated: Bool, completion: (() -> ())? = nil) {
        let animationBlock = {
            self.layout(inView: view, tiles: tiles)

            self.tileView.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: animationBlock) {
                completed in
                completion?()
            }
        }
        else {
            animationBlock()

            completion?()
        }
    }
    
    //MARK: Internal implementation

    private func effectiveAlignment() -> RowAlignment {
        if alignment == .auto {
            if #available(iOS 9.0, *) {
                return UIView.userInterfaceLayoutDirection(for: tileView.semanticContentAttribute) == .leftToRight ? .left : .right
            } else {
                return UIApplication.shared().userInterfaceLayoutDirection == .leftToRight ? .left : .right
            }
        }

        return alignment
    }

    private func numberOfColumns(_ count: Int) -> Int {
        let columns = count / maximumRows

        return columns + (count % maximumRows != 0 ? 1 : 0)
    }

    private func numberOfRowsForColumn(_ column: Int, tiles: [Tile]) -> Int {
        if fillDirection == .horizontal {
            let rows = tiles.count / maximumColumns

            return rows + (rows * maximumColumns < tiles.count ? 1 : 0)
        }

        var rows = 1
        var rowTiles = tilesForRow(rows, tiles: tiles)

        for _ in 0..<maximumRows {
            if rowTiles == nil || rowTiles![column] == nil {
                return rows
            }

            rows += 1
            rowTiles = tilesForRow(rows, tiles: tiles)
        }
        
        return rows
    }

    private func layout(inView view: UIView, tiles: [Tile]) {
        for row in 0..<maximumRows {
            guard let rowTiles = tilesForRow(row, tiles: tiles) else { break }

            for case let (index, tile?) in rowTiles.enumerated() {
                if let constraints = positionConstraints[tile] {
                    view.removeConstraints(constraints)
                }

                positionConstraints[tile] = [
                    topConstraintForTile(tile, view: view, tiles: tiles, row: row, rowTiles: rowTiles),
                    leftConstraintForTile(tile, view: view, tiles: tiles, row: row, index: index, rowTiles: rowTiles),
                ]

                view.addConstraints(positionConstraints[tile]!)

                view.removeConstraints(sizeConstraints[tile]!)

                sizeConstraints[tile] = sizeConstraintsForTile(tile, tiles: tiles, row: row, index: index, rowTiles: rowTiles)

                view.addConstraints(sizeConstraints[tile]!)
            }
        }
    }

    private func topConstraintForTile(_ tile: Tile, view: Tile, tiles: [Tile],
                                      row: Int, rowTiles: [Tile?]) -> NSLayoutConstraint {
        var topItem: Tile
        var topAttribute: NSLayoutAttribute

        if row == 0 {
            topItem = view
            topAttribute = .top
        }
        else {
            let prevRowTiles = tilesForRow(row - 1, tiles: tiles)!

            topItem = (effectiveAlignment() == .left ? prevRowTiles.first! : prevRowTiles.last!)!
            topAttribute = .bottom
        }

        return NSLayoutConstraint(item: tile, attribute: .top, relatedBy: .equal,
                                  toItem: topItem, attribute: topAttribute, multiplier: 1.0, constant: 0.0)
    }

    private func leftConstraintForTile(_ tile: Tile, view: Tile, tiles: [Tile],
                                       row: Int, index: Int, rowTiles: [Tile?]) -> NSLayoutConstraint {
        var item: Tile

        if effectiveAlignment() == .left {
            if fillDirection == .horizontal {
                item = index == 0 ? view : rowTiles[index - 1]!
            }
            else /* fillDirection == .vertical */ {
                item = index == 0 ? view : rowTiles[index - 1]!
            }
        }
        else /* alignment == .right */ {
            if fillDirection == .horizontal {
                item = index == 0 || rowTiles[index - 1] == nil ? view : rowTiles[index - 1]!
            }
            else /* fillDirection == .vertical */ {
                var effectiveRowTiles = row == 0 ? rowTiles : tilesForRow(0, tiles: tiles)

                item = index == 0 || effectiveRowTiles![index - 1] == nil ? view : effectiveRowTiles![index - 1]!
            }
        }

        let attribute: NSLayoutAttribute = item == view ? .left : .right

        return NSLayoutConstraint(item: tile, attribute: .left, relatedBy: .equal,
                                  toItem: item, attribute: attribute, multiplier: 1.0, constant: 0.0)
    }

    private func sizeConstraintsForTile(_ tile: Tile, tiles: [Tile],
                                        row: Int, index: Int, rowTiles: [Tile?]) -> [NSLayoutConstraint] {
        var tilesInRowCount: Int
        if fillDirection == .horizontal {
            let nonNilRowTiles = rowTiles.filter { return $0 != nil }
            tilesInRowCount = nonNilRowTiles.count
        }
        else {
            tilesInRowCount = rowTiles.count
        }

        let constraints = [
            sizeConstraints[tile]![0].adjustedConstraint(1.0 / CGFloat(tilesInRowCount)),
            sizeConstraints[tile]![1].adjustedConstraint(1.0 / CGFloat(numberOfRowsForColumn(index, tiles: tiles)))
        ]

        let adjustment = sizeAdjustments[tile]

        let widthAdjustment = adjustment?.0 ?? 0.0
        let heightAdjustment = adjustment?.1 ?? 0.0

        constraints[0].constant = widthAdjustment
        constraints[1].constant = heightAdjustment

        return constraints
    }

    private func tilesForRow(_ row: Int, tiles: [Tile]) -> [Tile?]? {
        var tilesForRow: [Tile?] = []

        if fillDirection == .horizontal {
            let startingIndex = row * maximumColumns

            for index in startingIndex..<(startingIndex + maximumColumns) {
                tilesForRow.append(index >= tiles.count ? nil : tiles[index])
            }
        }
        else /* if fillDirection == .vertical */ {
            guard row < maximumRows else { return nil }

            let columnCount = numberOfColumns(tiles.count)
            let startingIndex = row

            for index in startingIndex..<(startingIndex + columnCount) {
                let adjustedIndex = row + ((index - startingIndex) * maximumRows)

                tilesForRow.append(adjustedIndex >= tiles.count ? nil : tiles[adjustedIndex])
            }
        }

        if effectiveAlignment() == .left {
            return tilesForRow
        }
        else /* if alignment == .right */ {
            return tilesForRow.reversed()
        }
    }

}
