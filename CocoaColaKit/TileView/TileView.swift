//
//  TileView.swift
//  TileView
//
//  Created by Avi Shevin on 07/07/2016.
//  Copyright © 2016 Rounds. All rights reserved.
//

import UIKit

/// A TileView lays out its subviews such that they fill the client area.  The layout strategy is configurable.
public class TileView: UIView {

    /// The tiles.  Equivalent to `subviews`, except that tiles may be in a different order.
    private(set) public var tiles: [UIView] = []

    let layout: TileViewLayout!

    //MARK: Subclassing

    required public init?(coder aDecoder: NSCoder) {
        layout = TileViewLayoutRightThenDown(maximumRows: 1, maximumColumns: 1)

        super.init(coder: aDecoder)
    }

    override public func addSubview(_ view: UIView) {
        addTile(view)
    }

    override public func setNeedsLayout() {
        layout.adjustConstraints(false)

        super.setNeedsLayout()
    }

    //MARK: API

    /**
     Creates a TileView with the specified maximum number of rows and columns, using the specified layout.
     
     - Parameters:
        - maximumRows:    Optional.  The maximum number of rows which will be layed out.  Defaults to 1.
        - maximumColumns: Optional.  The maximum number of columns which will be layed out.  Defaults to 1.
        - layout:         Optional.  The layout to use.  Default is `.rightThenDown`.
     
     - Returns: A TileView configured appropriately.
     */
    public init(maximumRows: Int = 1, maximumColumns: Int = 1, layout: TileViewLayoutType = .rightThenDown) {
        switch layout {
        case .leftThenDown:
            self.layout = TileViewLayoutLeftThenDown(maximumRows: maximumRows, maximumColumns: maximumColumns)
        case .rightThenDown:
            self.layout = TileViewLayoutRightThenDown(maximumRows: maximumRows, maximumColumns: maximumColumns)
        case .downThenLeft:
            self.layout = TileViewLayoutDownThenLeft(maximumRows: maximumRows, maximumColumns: maximumColumns)
        case .downThenRight:
            self.layout = TileViewLayoutDownThenRight(maximumRows: maximumRows, maximumColumns: maximumColumns)
        }

        super.init(frame: CGRect())

        self.layout.tileView = self
    }

    /**
     Adds a `UIView` as a tile.  Tiles are added at the last position, as defined by the layout property.  The existing tiles are resized to fit.
     
     - Parameters:
        - tile:     The view to add.
        - animated: If true, the tile is added to the TileView using an animation.
     */
    public func addTile(_ tile: UIView, animated: Bool = true) {
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

        layout.clearContraints(tile)

        layout.adjustConstraints(animated)
    }
    
    /**
     Inserts a `UIView` as a tile.  The tile is inserted at the specified position.  The existing tiles are resized to fit.

     - Parameters:
        - tile:     The view to insert.
        - at:       The index of the tile to remove.  The index must be between `0` and `tiles.count`.
        - animated: If true, the tile is inserted into the TileView using an animation.
     */
    public func insertTile(_ tile: UIView, at: Int, animated: Bool = true) {
        guard tiles.count < layout.maximumRows * layout.maximumColumns else { return }

        tiles.insert(tile, at: at)

        tile.translatesAutoresizingMaskIntoConstraints = false

        super.addSubview(tile)

        if (animated) {
            layout.positionForAnimation(tile)
        }

        layout.addSizeConstraints(tile)
        layout.adjustConstraints(animated)
    }

    /**
     Replaces one tile with a different view.  The original tile is removed from the TileView.

     - Parameters:
        - tile:     The tile to be replaced.
        - view:     The view to replace the tile with.
        - animated: If true, the tile is replaced using an animation.
     */
    public func replaceTile(_ tile: UIView, with view: UIView, animated: Bool = true) {
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

        layout.adjustConstraints(animated)
    }

}
