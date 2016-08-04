//
//  TileView.swift
//  TileView
//
//  Created by Avi Shevin on 07/07/2016.
//  Copyright © 2016 Rounds. All rights reserved.
//

import UIKit

public typealias Tile = UIView

/// A TileView lays out its subviews such that they fill the client area.  The layout strategy is configurable.
public class TileView: UIView {

    /// The tiles.  Equivalent to `subviews`, except that tiles may be in a different order.
    private(set) public var tiles: [Tile] = []

    public var maximumTileCount: Int {
        get {
            return layout.maximumRows * layout.maximumColumns
        }
    }

    let layout: TileViewLayout!

    //MARK: Subclassing

    required public init?(coder aDecoder: NSCoder) {
        layout = TileViewLayout(maximumRows: 1, maximumColumns: 1, alignment: .left, fillDirection: .horizontal)

        super.init(coder: aDecoder)
    }

    override public func addSubview(_ view: Tile) {
        addTile(view)
    }

    override public func setNeedsLayout() {
        layout.layout(inView: self, tiles: tiles, animated: false)

        super.setNeedsLayout()
    }

    //MARK: API

    /**
     Creates a TileView with the specified maximum number of rows and columns, using the specified layout.
     
     - Parameters:
        - maximumRows:    Optional.  The maximum number of rows which will be layed out.  Defaults to 1.
        - maximumColumns: Optional.  The maximum number of columns which will be layed out.  Defaults to 1.
        - alignment:      Optional.  The alignment of newly-added tiles.
        - fillDirection:  Optional.  The policy for filling empty space.
     
     - Returns: A TileView configured appropriately.
     */
    public init(maximumRows: Int = 1, maximumColumns: Int = 1,
                alignment: RowAlignment = .left, fillDirection: FillDirection = .horizontal) {

        self.layout = TileViewLayout(maximumRows: max(maximumRows, 1), maximumColumns: max(maximumColumns, 1),
                                     alignment: alignment, fillDirection: fillDirection)

        super.init(frame: CGRect())

        self.layout.tileView = self
    }

    /**
     Adds a `UIView` as a tile.  Tiles are added at the last position, as defined by the layout property.  The existing tiles are resized to fit.
     
     - Parameters:
        - tile:     The view to add.
        - animated: If true, the tile is added to the TileView using an animation.
     */
    public func addTile(_ tile: Tile, animated: Bool = true) {
        insertTile(tile, at: tiles.count, animated: animated)
    }

    /**
     Removes the tile at the given index.  The remaining tiles will be resized to fill the empty space.
     
     - Parameters:
        - at:       The index of the tile to remove.  The index must be between `0` and `tiles.count - 1`.
        - animated: If true, the tile is removed from the TileView using an animation.
     */
    public func removeTile(_ at: Int, animated: Bool = true) {
        guard at < tiles.count && at >= 0 else { return }

        let tile = tiles[at]

        tile.removeFromSuperview()
        tiles.remove(at: at)

        layout.clearPositionInformation(tile)

        layout.layout(inView: self, tiles: tiles, animated: animated)
    }
    
    /**
     Inserts a `UIView` as a tile.  The tile is inserted at the specified position.  The existing tiles are resized to fit.

     - Parameters:
        - tile:     The view to insert.
        - at:       The index of the tile to remove.  The index must be between `0` and `tiles.count`.
        - animated: If true, the tile is inserted into the TileView using an animation.
     */
    public func insertTile(_ tile: Tile, at: Int, animated: Bool = true) {
        guard tiles.count < layout.maximumRows * layout.maximumColumns else { return }

        if animated {
            let placeholder = UIView()
            placeholder.translatesAutoresizingMaskIntoConstraints = false
            placeholder.backgroundColor = UIColor.clear()

            tiles.insert(placeholder, at: at)

            super.addSubview(placeholder)

            layout.addSizeConstraints(placeholder)
            layout.layout(inView: self, tiles: tiles, animated: animated) {
                tile.translatesAutoresizingMaskIntoConstraints = false

                self.tiles[at] = tile

                self.layout.placeTileForAnimatedReplacement(tile, placeholder: placeholder)

                super.insertSubview(tile, at: 0)
                placeholder.removeFromSuperview()

                self.layout.replaceTile(placeholder, with: tile, animated: animated)
            }

            return
        }

        tiles.insert(tile, at: at)

        tile.translatesAutoresizingMaskIntoConstraints = false

        super.addSubview(tile)

        layout.addSizeConstraints(tile)
        layout.layout(inView: self, tiles: tiles, animated: animated)
    }

    /**
     Replaces one tile with a different view.  The original tile is removed from the TileView.

     - Parameters:
        - tile:     The tile to be replaced.
        - view:     The view to replace the tile with.
        - animated: If true, the tile is replaced using an animation.
     */
    public func replaceTile(_ tile: Tile, with view: Tile, animated: Bool = true) {
        guard let index = tiles.index(of: tile) else { return }

        view.translatesAutoresizingMaskIntoConstraints = false

        tiles[index] = view

        super.addSubview(view)
        tile.removeFromSuperview()

        layout.replaceTile(tile, with: view, animated: animated)
    }
    
    /**
     Swaps the position of two tiles.

     - Parameters:
         - a:           The first index.
         - b:           The second index.
         - animated:    If true, the tiles are swapped using an animation.
     */
    public func swap(_ a: Int, with b: Int, animated: Bool = true) {
        let aTile = tiles[a]
        let bTile = tiles[b]

        tiles[a] = bTile
        tiles[b] = aTile

        layout.clearSizeAdjustments()
        layout.layout(inView: self, tiles: tiles, animated: animated)
    }

    /**
     Adjusts a tile's width or height by the specified amount.  The adjustment is made by adding the given amount to the nominal size.  Adjustments are cumulative.  All adjustments are cleared when `swap(:with:animated:)` is called.
     
     - Parameters:
        - tile:         The tile whose size will be adjusted.
        - width:        The amount by which to adjust the width.  Ignored when fillDirection is vertical.
        - height:       The amount by which to adjust the height.  Ignored when fillDirection is horizontal.
     */
    public func adjustTile(_ tile: Tile, widthBy width: CGFloat = 0.0, heightBy height: CGFloat = 0.0) {
        layout.adjustTile(tile, widthBy: width, heightBy: height)
    }
}
