//
//  ChatSkeletonView.swift
//  Cloverly
//
//
//

import UIKit
import SnapKit

/// 채팅 히스토리 조회 동안 보여줄 스켈레톤.
/// 유저(우측)/AI(좌측 프로필 원 + 말풍선)가 번갈아 배치되며 shimmer가 흐른다.
final class ChatSkeletonView: UIView {

    // 실제 말풍선과 동일한 코너 마스킹 (한쪽 아래 모서리만 각지게)
    private static let aiCorners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    private static let userCorners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]

    // 실제 프로필 이미지 크기(36pt)와 동일
    private let profileSize: CGFloat = 36

    // (isAI, width, height) — 유저가 먼저 보낸 대화처럼 유저→AI 순으로 번갈아 배치 (4쌍)
    private let rows: [(isAI: Bool, width: CGFloat, height: CGFloat)] = [
        (false, 120, 40),
        (true, 190, 44),
        (false, 96, 40),
        (true, 224, 62),
        (false, 205, 58),
        (true, 150, 44),
        (false, 176, 40),
        (true, 200, 56)
    ]

    private var bubbles: [SkeletonBubble] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 24
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview()
        }

        for row in rows {
            stack.addArrangedSubview(makeRow(row))
        }
    }

    private func makeRow(_ row: (isAI: Bool, width: CGFloat, height: CGFloat)) -> UIView {
        let container = UIView()

        let bubble = SkeletonBubble()
        bubble.layer.maskedCorners = row.isAI ? Self.aiCorners : Self.userCorners
        bubbles.append(bubble)
        container.addSubview(bubble)

        bubble.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.width.equalTo(row.width)
            $0.height.equalTo(row.height)
        }

        if row.isAI {
            // AI: 좌측 프로필 원 + 말풍선
            let profile = SkeletonBubble()
            profile.layer.cornerRadius = profileSize / 2
            profile.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            bubbles.append(profile)
            container.addSubview(profile)

            profile.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(16)
                $0.bottom.equalTo(bubble.snp.bottom)
                $0.width.height.equalTo(profileSize)
            }
            bubble.snp.makeConstraints {
                $0.leading.equalTo(profile.snp.trailing).offset(8)
            }
        } else {
            // 유저: 우측 정렬 말풍선
            bubble.snp.makeConstraints {
                $0.trailing.equalToSuperview().offset(-16)
            }
        }

        return container
    }

    func startShimmer() {
        bubbles.forEach { $0.startShimmer() }
    }

    func stopShimmer() {
        bubbles.forEach { $0.stopShimmer() }
    }
}

/// gray9 배경 위로 밝은 하이라이트가 좌→우로 흐르는 shimmer 플레이스홀더.
final class SkeletonBubble: UIView {
    private let gradient = CAGradientLayer()
    private var isShimmering = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .gray9
        layer.cornerRadius = 16
        clipsToBounds = true

        let base = UIColor.gray9.cgColor
        let highlight = UIColor.white.withAlphaComponent(0.7).cgColor
        gradient.colors = [base, highlight, base]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.locations = [0, 0.5, 1]
        layer.addSublayer(gradient)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    // 뷰가 윈도우에 붙는 시점(프레임 확정)에 애니메이션을 재적용해
    // 오프스크린/제로프레임에서 시작돼 멈춰 보이는 문제를 방지한다.
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if isShimmering, window != nil {
            addShimmerAnimation()
        }
    }

    func startShimmer() {
        isShimmering = true
        if window != nil {
            addShimmerAnimation()
        }
    }

    func stopShimmer() {
        isShimmering = false
        gradient.removeAnimation(forKey: "shimmer")
    }

    private func addShimmerAnimation() {
        gradient.removeAnimation(forKey: "shimmer")
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.2
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        gradient.add(animation, forKey: "shimmer")
    }
}
