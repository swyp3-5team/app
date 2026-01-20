//
//  NoticeDetailViewController.swift
//  Cloverly
//
//  Created by 이인호 on 1/4/26.
//

import UIKit
import SnapKit

class NoticeDetailViewController: UIViewController {
    
    private let notice: Notice
    
    // 제목
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardMedium, size: 16)
        label.textColor = .gray1
        label.numberOfLines = 0
        return label
    }()
    
    // 날짜
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .customFont(.pretendardRegular, size: 14)
        label.textColor = .gray3
        return label
    }()
    
    // 구분선
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray9 // 연한 회색
        return view
    }()
    
    // 내용 (스크롤 가능)
    private let contentTextView: UITextView = {
        let view = UITextView()
        view.font = .customFont(.pretendardRegular, size: 15)
        view.textColor = .gray1
        view.isEditable = false // 읽기 전용
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    init(notice: Notice) {
        self.notice = notice
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        configure()
    }
    
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(dateLabel)
        view.addSubview(dividerView)
        view.addSubview(contentTextView)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.equalTo(titleLabel)
        }
        
        dividerView.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(1)
        }
        
        contentTextView.snp.makeConstraints {
            $0.top.equalTo(dividerView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }
    }
    
    private func configure() {
        title = notice.title
        titleLabel.text = notice.title
        contentTextView.text = notice.content
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        dateLabel.text = formatter.string(from: notice.createdAt)
    }
}
