//
// GeometryHelpers.swift
//
// Copyright © 2016 Kimmo Kulovesi, https://github.com/arkku/
//

import CoreGraphics

public extension CGSize {
    /// Create a square with width and height both equal to `dimension`.
    public init(square dimension: CGFloat) {
        self.init(width: dimension, height: dimension)
    }

    /// A `CGRect` with this size and zero origin.
    public var rectangleAtOrigin: CGRect {
        return CGRect(origin: .zero, size: self)
    }

    /// The size rounded up to the nearest integer.
    public var roundedUp: CGSize {
        return ceil(self)
    }

    /// The size rounded.
    public var rounded: CGSize {
        return round(self)
    }

    /// The size rounded down to the nearest integer.
    public var roundedDown: CGSize {
        return floor(self)
    }

    /// A size capped to be no greater in either dimension than `maxDimensions`.
    public func capped(toAtMost maxDimensions: CGSize) -> CGSize {
        return CGSize(width: min(width, maxDimensions.width), height: min(height, maxDimensions.height))
    }

    /// A size to capped to be no smaller in either dimension than `minDimensions`.
    public func capped(toAtLeast minDimensions: CGSize) -> CGSize {
        return CGSize(width: max(width, minDimensions.width), height: max(height, minDimensions.height))
    }

    /// Compute a suitable square cell size to evenly fill a container of `containerWidth`
    /// with at least `minimumCellsPerRow` cells, with `edgeMargin` between the cells
    /// and the container edges, and `spacing` between adjacent cells. The cells will
    /// try to have at least `minimumCellWidth` size, but will be smaller if
    /// `minimumCellsPerRow` requires it
    public static func squareSize(toFillWidth containerWidth: CGFloat, withNoFewerThan minimumCellsPerRow: Int, cellsWiderThan minimumCellWidth: CGFloat, spacedApartBy spacing: CGFloat = 0, edgeMargin: CGFloat = 0) -> CGSize {
        var width = containerWidth - edgeMargin * 2

        let minimumWidth = Int(minimumCellWidth + spacing / 2)
        var cellsPerRow = (minimumWidth > 0) ? Int(width / CGFloat(minimumWidth)) : 1
        cellsPerRow = max(cellsPerRow, minimumCellsPerRow, 1)

        // Subtract margins in between cells to get the available width for cells
        width -= spacing * CGFloat(cellsPerRow - 1)
        // Divide width among cells and round down
        width /= CGFloat(cellsPerRow)

        return CGSize(square: width)
    }
}

/// Round both both width and height of `size` down to the nearest integer.
public func floor(_ size: CGSize) -> CGSize {
    return CGSize(width: floor(size.width), height: floor(size.height))
}

/// Round both both width and height of `size` up to the nearest integer.
public func ceil(_ size: CGSize) -> CGSize {
    return CGSize(width: ceil(size.width), height: ceil(size.height))
}

/// Round both both width and height of `size` to the nearest integer.
public func round(_ size: CGSize) -> CGSize {
    return CGSize(width: round(size.width), height: round(size.height))
}

public extension CGRect {
    /// Midpoint of the frame.
    public var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }

    /// Move `origin.x` so that the frame is to the right of `sibling` with a
    /// margin of `dx`.
    public mutating func move(rightOf sibling: CGRect, margin dx: CGFloat = 0) {
        origin.x = sibling.maxX + dx
    }

    /// Move `origin.x` so that the frame is to the left of `sibling` with a
    /// margin of `dx`.
    public mutating func move(leftOf sibling: CGRect, margin dx: CGFloat = 0) {
        origin.x = sibling.minX - width - dx
    }

    /// Move `origin.x` so that the frame is aligned to the right edge of `parent`
    /// _in its coordinates_, with a margin of `dx`.
    public mutating func move(insideRightEdgeOf parent: CGRect, margin dx: CGFloat = 0) {
        origin.x = parent.width - width - dx
    }

    /// Move `origin.x` so that the frame is aligned to the left edge of `parent`
    /// _in its coordinates_, with a margin of `dx`.
    public mutating func move(insideLeftEdgeOf parent: CGRect, margin dx: CGFloat = 0) {
        origin.x = dx
    }

    /// Move `origin.y` so that the frame is above `sibling` with a margin of `dx`.
    public mutating func move(above sibling: CGRect, margin dy: CGFloat = 0) {
        origin.y = sibling.minY - height - dy
    }

    /// Move `origin.y` so that the frame is below `sibling` with a margin of `dx`.
    public mutating func move(below sibling: CGRect, margin dy: CGFloat = 0) {
        origin.y = sibling.maxY + dy
    }

    /// Move `origin.y` so that the frame is aligned to the top edge of `parent`
    /// _in its coordinates_, with a margin of `dy`.
    public mutating func move(insideTopEdgeOf parent: CGRect, margin dy: CGFloat = 0) {
        origin.y = dy
    }

    /// Move `origin.y` so that the frame is aligned to the bottom edge of `parent`
    /// _in its coordinates_, with a margin of `dy`.
    public mutating func move(insideBottomEdgeOf parent: CGRect, margin dy: CGFloat = 0) {
        origin.y = parent.height - height - dy
    }

    /// Move `origin.x` to the horizontal center of `sibling`, with an offset of `dx`.
    public mutating func move(centeredHorizontallyWith sibling: CGRect, offset dx: CGFloat = 0) {
        origin.x = (sibling.midX - (width / 2)) + dx
    }

    /// Move `origin.y` to the vertical center of `sibling`, with an offset of `dy`.
    public mutating func move(centeredVerticallyWith sibling: CGRect, offset dy: CGFloat = 0) {
        origin.y = (sibling.midY - (height / 2)) + dy
    }

    /// Move `origin.x` so that the frame is centered horizontally inside `parent`
    /// _in its coordinates_, with an offset of `dx`.
    public mutating func move(centeredHorizontallyInside parent: CGRect, offset dx: CGFloat = 0) {
        origin.x = ((parent.width / 2) - (width / 2)) + dx
    }

    /// Move `origin.y` so that the frame is centered vertically inside `parent`
    /// _in its coordinates_, with an offset of `dy`.
    public mutating func move(centeredVerticallyInside parent: CGRect, offset dy: CGFloat = 0) {
        origin.y = ((parent.height / 2) - (height / 2)) + dy
    }
}

public extension CGPoint {
    /// The point moved right by `dx`.
    public func moved(right dx: CGFloat) -> CGPoint {
        return CGPoint(x: x + dx, y: y)
    }

    /// Move the point right by `dx`.
    public mutating func move(right dx: CGFloat) {
        x += dx
    }

    /// The point moved left by `dx`.
    public func moved(left dx: CGFloat) -> CGPoint {
        return CGPoint(x: x - dx, y: y)
    }

    /// Move the point left by `dx`.
    public mutating func move(left dx: CGFloat) {
        x -= dx
    }

    /// The point moved down by `dy`.
    public func moved(down dy: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: y + dy)
    }

    /// Move the point down by `dy`.
    public mutating func move(down dy: CGFloat) {
        y += dy
    }

    /// The point moved up by `dy`.
    public func moved(up dy: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: y - dy)
    }

    /// Move the point up by `dy`.
    public mutating func move(up dy: CGFloat) {
        y -= dy
    }
}

public extension CGAffineTransform {
    /// Create a scale transform with equal X and Y scale.
    public init(scale: CGFloat) {
        self.init(scaleX: scale, y: scale)
    }

    /// A transform that flips the vertical axis (i.e., `y` will be zero at the bottom).
    public static let flipVertically = CGAffineTransform(scaleX: 1, y: -1)

    /// A transform that mirrors the horizontal axis.
    public static let mirrorHorizontally = CGAffineTransform(scaleX: -1, y: 1)
}
