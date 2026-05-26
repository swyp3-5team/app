//
//  TooltipView.swift
//  Cloverly
//
//  Created by 이인호 on 5/6/26.
//

import UIKit

final class TooltipView: UIView {
    private let label: UILabel = {
        let label = UILabel()
        label.textColor = .gray1
        label.font = Typography.b6.uiFont
        label.numberOfLines = 0
        return label
    }()

    private let closeButton: UIButton = {
        let btn = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .regular)
        btn.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        btn.tintColor = .gray3
        return btn
    }()

    private static weak var current: TooltipView?
    private weak var overlayView: UIView?

    static func show(from sourceView: UIView, text: String) {
        if let existing = current {
            existing.dismiss()
            return
        }

        guard let window = sourceView.window else { return }

        let tooltip = TooltipView()
        tooltip.label.text = text

        // 툴팁 내부 여백 및 X 버튼 크기 상수
        let closeSize: CGFloat = 10
        let hPadding: CGFloat = 12
        let vPadding: CGFloat = 10
        // 라벨이 쓸 수 있는 최대 너비 = 전체 최대 - 좌우 패딩 - X 버튼 영역
        let labelMaxWidth: CGFloat = 400 - hPadding * 2 - closeSize - 4

        // 텍스트 내용에 맞는 라벨 실제 크기 계산
        let labelSize = tooltip.label.sizeThatFits(CGSize(width: labelMaxWidth, height: .greatestFiniteMagnitude))
        // 툴팁 전체 크기 = 라벨 + 패딩 + X 버튼
        let tooltipWidth = labelSize.width + hPadding * 2 + closeSize + 4
        // 높이는 라벨 기준이지만 X 버튼보다 작아지지 않도록 max 처리
        let tooltipHeight = max(labelSize.height + vPadding * 2, closeSize + vPadding * 2)

        // sourceView(i 버튼)의 frame을 window 좌표계로 변환
        let sourceFrame = sourceView.convert(sourceView.bounds, to: window)
        // i 버튼 leading에 맞추되 화면 오른쪽을 벗어나면 왼쪽으로 당김
        let rawX = sourceFrame.minX - 8
        let x = min(rawX, window.bounds.width - tooltipWidth - 16)
        // i 버튼 바로 아래에 위치
        let y = sourceFrame.maxY

        tooltip.frame = CGRect(x: x, y: y, width: tooltipWidth, height: tooltipHeight)
        tooltip.backgroundColor = .white
        tooltip.layer.cornerRadius = 8
        tooltip.layer.borderWidth = 1
        tooltip.layer.borderColor = UIColor.gray8.cgColor

        tooltip.addSubview(tooltip.label)
        tooltip.addSubview(tooltip.closeButton)

        // 라벨: 좌측 패딩에서 시작
        tooltip.label.frame = CGRect(
            x: hPadding,
            y: vPadding,
            width: labelSize.width,
            height: labelSize.height
        )

        // X 버튼: 우측 패딩 기준으로 끝에 배치
        tooltip.closeButton.frame = CGRect(
            x: tooltipWidth - hPadding - closeSize,
            y: vPadding,
            width: closeSize,
            height: closeSize
        )

        tooltip.closeButton.addAction(UIAction { [weak tooltip] _ in
            tooltip?.dismiss()
        }, for: .touchUpInside)

        // tooltip 뒤에 전체화면 투명 뷰를 깔아서 바깥 탭을 잡음
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = .clear
        overlay.addGestureRecognizer(UITapGestureRecognizer(target: tooltip, action: #selector(dismiss)))
        window.addSubview(overlay)
        window.addSubview(tooltip)
        tooltip.overlayView = overlay

        tooltip.alpha = 0
        UIView.animate(withDuration: 0.2) { tooltip.alpha = 1 }

        current = tooltip
    }

    @objc func dismiss() {
        overlayView?.removeFromSuperview()
        UIView.animate(withDuration: 0.15, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
        TooltipView.current = nil
    }
}
