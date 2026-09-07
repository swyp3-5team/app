//
//  UIImage+Resize.swift
//  Cloverly
//

import UIKit

extension UIImage {
    /// 긴 변을 maxDimension(픽셀)으로 축소한다. 비율 유지, 원본이 더 작으면 확대하지 않음.
    /// EXIF orientation을 정규화한 up 방향 이미지를 반환한다.
    func resized(maxDimension: CGFloat) -> UIImage {
        // UIImage.size는 point 기준이라, scale을 곱해 실제 픽셀 크기로 판단
        let pixelWidth = size.width * scale
        let pixelHeight = size.height * scale
        let longSide = max(pixelWidth, pixelHeight)

        // 이미 충분히 작으면 방향만 정규화
        guard longSide > maxDimension else {
            return normalizedUp(pixelSize: CGSize(width: pixelWidth, height: pixelHeight))
        }

        let ratio = maxDimension / longSide
        let targetSize = CGSize(width: pixelWidth * ratio, height: pixelHeight * ratio)
        return normalizedUp(pixelSize: targetSize)
    }

    /// 지정한 픽셀 크기로 다시 그려 orientation을 up으로 정규화 (scale = 1).
    private func normalizedUp(pixelSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)
        return renderer.image { _ in
            // draw(in:)은 imageOrientation을 반영해 올바른 방향으로 그린다
            draw(in: CGRect(origin: .zero, size: pixelSize))
        }
    }
}
