//
//  UIView+extensions.swift
//  CocoaColaKit
//
//  Created by Avi Shevin on 01/08/2016.
//  Copyright © 2016 Avi Shevin. All rights reserved.
//

import UIKit

extension UIView {

    public func fillWithView(_ view: UIView, insets: UIEdgeInsets = UIEdgeInsetsZero) {
        if view.superview != self {
            addSubview(view)
        }

        addConstraints([
            NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal,
                               toItem: self, attribute: .top, multiplier: 1.0,
                               constant: insets.top),

            NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal,
                               toItem: self, attribute: .bottom, multiplier: 1.0,
                               constant: insets.bottom),

            NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal,
                               toItem: self, attribute: .left, multiplier: 1.0,
                               constant: insets.left),

            NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal,
                               toItem: self, attribute: .right, multiplier: 1.0,
                               constant: insets.right),
            ])
    }

}
