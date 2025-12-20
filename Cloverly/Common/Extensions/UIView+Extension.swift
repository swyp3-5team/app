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
        blur: CGFloat = 2,
        cornerRadius: CGFloat = 20
    ) {
        layer.cornerRadius = cornerRadius
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = alpha
        layer.shadowOffset = CGSize(width: 0, height: yOffset)
        layer.shadowRadius = blur
        layer.masksToBounds = false
        
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        layer.shadowPath = path.cgPath
    }
}
