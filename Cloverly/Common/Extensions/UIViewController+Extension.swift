//
//  UIViewController+Extension.swift
//  Cloverly
//
//  Created by 이인호 on 12/27/25.
//

import UIKit
import SnapKit

extension UIViewController {
    
    func showToast(message: String, buttonTitle: String? = nil, duration: TimeInterval = 2.0, action: (() -> Void)? = nil) {
        
        let toastView = ToastView(message: message, buttonTitle: buttonTitle ?? "")
        
        toastView.onActionTap = {
            action?()
            
            UIView.animate(withDuration: 0.3, animations: {
                toastView.alpha = 0
            }) { _ in
                toastView.removeFromSuperview()
            }
        }
        
        view.addSubview(toastView)
        toastView.alpha = 0
        
        toastView.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-127)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }
        
        // 나타나기(Fade In) -> 대기 -> 사라지기(Fade Out)
        UIView.animate(withDuration: 0.5, animations: {
            toastView.alpha = 1.0
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                guard toastView.superview != nil else { return }
                
                UIView.animate(withDuration: 0.5, animations: {
                    toastView.alpha = 0.0
                }) { _ in
                    toastView.removeFromSuperview()
                }
            }
        }
    }
}
