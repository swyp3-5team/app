//
//  UIView+Extension.swift
//  Cloverly
//
//  Created by 이인호 on 12/16/25.
//

import UIKit

extension UIView {
    func applyTopShadow(
        color: UIColor = .black,
        alpha: Float = 0.1,
        yOffset: CGFloat = -2,
        blur: CGFloat = 2
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = alpha
        layer.shadowOffset = CGSize(width: 0, height: yOffset)
        layer.shadowRadius = blur
        
        let path = UIBezierPath(rect: CGRect(
            x: 0,
            y: -blur,
            width: bounds.width,
            height: blur
        ))
        layer.shadowPath = path.cgPath
    }
}
