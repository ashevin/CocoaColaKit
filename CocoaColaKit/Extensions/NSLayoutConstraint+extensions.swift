//
//  NSContsraint+extensions.swift
//  TileView
//
//  Created by Avi Shevin on 21/07/2016.
//  Copyright © 2016 Rounds. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {

    public func adjustedConstraint(multiplier: CGFloat) -> NSLayoutConstraint {
        let firstItem = self.firstItem
        let secondItem = self.secondItem
        let relation = self.relation
        let firstAttribute = self.firstAttribute
        let secondAttribute = self.secondAttribute
        let constant = self.constant
        let priority = self.priority

        let newConstraint = NSLayoutConstraint(item: firstItem, attribute: firstAttribute, relatedBy: relation, toItem: secondItem, attribute: secondAttribute, multiplier: multiplier, constant: constant)

        newConstraint.priority = priority

        return newConstraint
    }

    public func adjustedConstraint(firstItem: UIView) -> NSLayoutConstraint {
        let secondItem = self.secondItem
        let relation = self.relation
        let firstAttribute = self.firstAttribute
        let secondAttribute = self.secondAttribute
        let multiplier = self.multiplier
        let constant = self.constant
        let priority = self.priority

        let newConstraint = NSLayoutConstraint(item: firstItem, attribute: firstAttribute, relatedBy: relation, toItem: secondItem, attribute: secondAttribute, multiplier: multiplier, constant: constant)

        newConstraint.priority = priority

        return newConstraint
    }

}
