//
//  CustomPageControl.swift
//  Cloverly
//
//  Created by 이인호 on 12/18/25.
//

import UIKit

import UIKit
import SnapKit

class CustomPageControl: UIView {
    
    // MARK: - Properties
    private var numberOfPages: Int = 0
    private var currentPage: Int = 0
    private var dots: [UIView] = []
    
    private let activeColor: UIColor = .green5
    private let inactiveColor: UIColor = .green9
    
    private let activeWidth: CGFloat = 28
    private let inactiveWidth: CGFloat = 8
    private let height: CGFloat = 8
    private let spacing: CGFloat = 12
    
    // MARK: - UI Components
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = spacing
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    // MARK: - Configuration
    /// 페이지 개수를 설정하고 점들을 생성합니다.
    func configure(numberOfPages: Int) {
        self.numberOfPages = numberOfPages
        setupDots()
    }
    
    private func setupDots() {
        // 기존 점들 제거 (초기화)
        dots.forEach { $0.removeFromSuperview() }
        dots.removeAll()
        
        for i in 0..<numberOfPages {
            let dot = UIView()
            dot.backgroundColor = (i == currentPage) ? activeColor : inactiveColor
            dot.layer.cornerRadius = height / 2
            dot.clipsToBounds = true
            
            // 초기 사이즈 제약조건 설정
            dot.snp.makeConstraints {
                $0.height.equalTo(height)
                $0.width.equalTo(i == currentPage ? activeWidth : inactiveWidth)
            }
            
            dots.append(dot)
            stackView.addArrangedSubview(dot)
        }
    }
    
    // MARK: - Update Logic (애니메이션 핵심)
    /// 현재 페이지를 변경하고 애니메이션을 실행합니다.
    func setCurrentPage(_ page: Int) {
        guard page >= 0 && page < numberOfPages && page != currentPage else { return }
        
        // 1. 상태 변경
        let oldIndex = currentPage
        let newIndex = page
        currentPage = newIndex
        
        // 2. 애니메이션 (너비와 색상 변경)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            
            // 이전 활성 점 -> 작아짐
            self.dots[oldIndex].backgroundColor = self.inactiveColor
            self.dots[oldIndex].snp.updateConstraints {
                $0.width.equalTo(self.inactiveWidth)
            }
            
            // 새로운 활성 점 -> 길어짐 (Capsule)
            self.dots[newIndex].backgroundColor = self.activeColor
            self.dots[newIndex].snp.updateConstraints {
                $0.width.equalTo(self.activeWidth)
            }
            
            // [중요] 레이아웃 즉시 갱신 (이게 있어야 스르륵 늘어남)
            self.layoutIfNeeded()
        }
    }
}
