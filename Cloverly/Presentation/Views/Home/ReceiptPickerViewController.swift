//
//  ReceiptPickerViewController.swift
//  Cloverly
//
//  커스텀 갤러리 시트.
//  0번 셀 = 카메라, 이후 셀 = 사진 썸네일. 사진/카메라로 이미지를 고르면 onPickImage로 전달
//  전체/제한적/거부 세 가지 사진 권한 상태를 모두 처리
//

import UIKit
import Photos
import SnapKit

final class ReceiptPickerViewController: UIViewController {
    /// 이미지 선택(사진 or 카메라) 완료 콜백. 시트가 닫힌 뒤 호출된다.
    var onPickImage: ((UIImage) -> Void)?

    private let imageManager = PHCachingImageManager()
    private var assets: PHFetchResult<PHAsset>?
    private var isFinishing = false

    private let columnCount = 3
    private let cellSpacing: CGFloat = 2

    // MARK: - UI

    private let titleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "최근 사진"
        label.textColor = .gray1
        label.typography = .b2
        label.textAlignment = .center
        return label
    }()

    private lazy var closeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "xmark")
        config.baseForegroundColor = .gray2
        let button = UIButton(configuration: config)
        button.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        return button
    }()

    private lazy var headerView: UIView = {
        let view = UIView()
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(52)
            $0.trailing.lessThanOrEqualToSuperview().offset(-52)
        }
        closeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-8)
            $0.centerY.equalToSuperview()
        }
        return view
    }()

    // 제한적 접근 안내 문구
    private let limitedDescriptionLabel: AppLabel = {
        let label = AppLabel()
        label.text = "선택한 사진만 볼 수 있어요"
        label.textColor = .gray2
        label.typography = .b6
        return label
    }()

    // 설정 앱의 권한 화면으로 이동시키는 primary 버튼
    private lazy var permissionSettingButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .green5
        config.baseForegroundColor = .white
        var titleAttr = AttributedString("권한 설정")
        titleAttr.font = Typography.b6.uiFont
        config.attributedTitle = titleAttr
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        let button = UIButton(configuration: config)
        button.addAction(UIAction { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }, for: .touchUpInside)
        return button
    }()

    // 제한적 접근일 때만 노출되는 배너: [문구 — spacer — 권한 설정 버튼]
    private lazy var limitedBanner: UIView = {
        let view = UIView()
        view.backgroundColor = .green11
        view.isHidden = true

        view.addSubview(limitedDescriptionLabel)
        view.addSubview(permissionSettingButton)

        limitedDescriptionLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        permissionSettingButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.leading.greaterThanOrEqualTo(limitedDescriptionLabel.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(14)
            $0.bottom.equalToSuperview().offset(-14)
        }
        return view
    }()

    private lazy var topStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerView, limitedBanner])
        stack.axis = .vertical
        return stack
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = cellSpacing
        layout.minimumLineSpacing = cellSpacing
        layout.sectionInset = .zero

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.alwaysBounceVertical = true
        cv.dataSource = self
        cv.delegate = self
        cv.register(ReceiptCameraCell.self, forCellWithReuseIdentifier: ReceiptCameraCell.reuseID)
        cv.register(ReceiptPhotoCell.self, forCellWithReuseIdentifier: ReceiptPhotoCell.reuseID)
        return cv
    }()

    // 권한 거부 시 노출되는 안내 뷰
    private lazy var deniedView: UIView = {
        let container = UIView()
        container.isHidden = true

        let label = AppLabel()
        label.text = "사진 접근 권한이 없어요.\n설정에서 권한을 허용해주세요."
        label.textColor = .gray3
        label.typography = .b3
        label.textAlignment = .center
        label.numberOfLines = 0

        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .gray9
        config.baseForegroundColor = .gray2
        var titleAttr = AttributedString("설정 열기")
        titleAttr.font = Typography.b5.uiFont
        config.attributedTitle = titleAttr
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        let button = UIButton(configuration: config)
        button.addAction(UIAction { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }, for: .touchUpInside)

        container.addSubview(label)
        container.addSubview(button)
        label.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        button.snp.makeConstraints {
            $0.top.equalTo(label.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        return container
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureUI()
        requestAuthorizationAndLoad()
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    private func configureUI() {
        view.addSubview(topStack)
        view.addSubview(collectionView)
        view.addSubview(deniedView)

        topStack.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }
        headerView.snp.makeConstraints { $0.height.equalTo(52) }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(topStack.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        deniedView.snp.makeConstraints {
            $0.edges.equalTo(collectionView)
        }
    }

    // MARK: - Photos

    private func requestAuthorizationAndLoad() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            handleGranted(status)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async { self?.handleGranted(newStatus) }
            }
        default:
            deniedView.isHidden = false
        }
    }

    private func handleGranted(_ status: PHAuthorizationStatus) {
        guard status == .authorized || status == .limited else {
            deniedView.isHidden = false
            return
        }
        deniedView.isHidden = true
        limitedBanner.isHidden = (status != .limited)
        PHPhotoLibrary.shared().register(self)
        fetchAssets()
    }

    private func fetchAssets() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        assets = PHAsset.fetchAssets(with: .image, options: options)
        collectionView.reloadData()
    }

    private var thumbnailSize: CGSize {
        let scale = UIScreen.main.scale
        let width = itemWidth
        return CGSize(width: width * scale, height: width * scale)
    }

    private var itemWidth: CGFloat {
        let totalSpacing = cellSpacing * CGFloat(columnCount - 1)
        return floor((collectionView.bounds.width - totalSpacing) / CGFloat(columnCount))
    }

    // MARK: - Selection

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    private func selectPhoto(_ asset: PHAsset) {
        guard !isFinishing else { return }
        isFinishing = true

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .none

        imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .default,
            options: options
        ) { [weak self] image, info in
            guard let self else { return }
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            guard let image, !isDegraded else { return }
            DispatchQueue.main.async { self.finish(with: image) }
        }
    }

    private func finish(with image: UIImage) {
        dismiss(animated: true) { [weak self] in
            self?.onPickImage?(image)
        }
    }
}

// MARK: - UICollectionView

extension ReceiptPickerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1 + (assets?.count ?? 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: ReceiptCameraCell.reuseID, for: indexPath)
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReceiptPhotoCell.reuseID, for: indexPath) as! ReceiptPhotoCell
        guard let asset = assets?.object(at: indexPath.item - 1) else { return cell }

        let identifier = asset.localIdentifier
        cell.representedAssetIdentifier = identifier
        imageManager.requestImage(
            for: asset,
            targetSize: thumbnailSize,
            contentMode: .aspectFill,
            options: nil
        ) { image, _ in
            if cell.representedAssetIdentifier == identifier {
                cell.imageView.image = image
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            openCamera()
        } else if let asset = assets?.object(at: indexPath.item - 1) {
            selectPhoto(asset)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: itemWidth, height: itemWidth)
    }
}

// MARK: - UIImagePickerControllerDelegate (카메라)

extension ReceiptPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self, let image = info[.originalImage] as? UIImage else { return }
            self.finish(with: image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - PHPhotoLibraryChangeObserver (제한적 접근 갱신)

extension ReceiptPickerViewController: PHPhotoLibraryChangeObserver {
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor [weak self] in
            self?.fetchAssets()
        }
    }
}

// MARK: - Cells

final class ReceiptCameraCell: UICollectionViewCell {
    static let reuseID = "ReceiptCameraCell"

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .gray9

        let iconView = UIImageView(image: UIImage(named: "camera icon"))
        iconView.contentMode = .scaleAspectFit

        let label = AppLabel()
        label.text = "카메라"
        label.textColor = .gray2
        label.typography = .b6
        label.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6

        contentView.addSubview(stack)
        iconView.snp.makeConstraints { $0.width.height.equalTo(28) }
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ReceiptPhotoCell: UICollectionViewCell {
    static let reuseID = "ReceiptPhotoCell"
    var representedAssetIdentifier: String?

    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        representedAssetIdentifier = nil
    }
}
