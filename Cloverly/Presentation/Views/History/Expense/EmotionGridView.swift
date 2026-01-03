//
//  EmotionGridView.swift
//  Cloverly
//
//  Created by 이인호 on 1/3/26.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class EmotionGridView: UIView {
    
    // 📡 외부(VC)에서 선택된 값을 구독할 수 있는 변수
    let selectedEmotion = PublishRelay<Emotion>()
    private let disposeBag = DisposeBag()
    
    // 데이터
    private let emotions = Emotion.allCases
    
    // 컬렉션뷰
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8 // 가로 간격
        layout.minimumLineSpacing = 8      // 세로 간격
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(EmotionCell.self, forCellWithReuseIdentifier: "EmotionCell")
        cv.dataSource = self
        cv.delegate = self
        cv.isScrollEnabled = false
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // 초기 선택값 설정 (예: 수정 화면 들어왔을 때)
    func select(emotion: Emotion) {
        guard let index = emotions.firstIndex(of: emotion) else { return }
        let indexPath = IndexPath(item: index, section: 0)
        
        // UI 선택 처리
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
    }
}

extension EmotionGridView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emotions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmotionCell", for: indexPath) as? EmotionCell else { return UICollectionViewCell() }
        cell.configure(emotion: emotions[indexPath.item])
        return cell
    }
    
    // ✨ 3열 계산 로직 (여기가 제일 중요)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 전체 너비 - (사이 간격 합계)
        // ------------------------
        //            3
        let spacing: CGFloat = 8
        let totalSpacing = spacing * 2
        let width = (collectionView.bounds.width - totalSpacing) / 3
        
        return CGSize(width: width, height: 97)
    }
    
    // 선택 이벤트 전달
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emotion = emotions[indexPath.item]
        selectedEmotion.accept(emotion) // 📡 선택됐다고 쏘기!
    }
}
