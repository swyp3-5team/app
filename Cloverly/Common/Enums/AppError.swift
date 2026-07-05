//
//  AppError.swift
//  Cloverly
//
//  Created by 이인호 on 7/5/26.
//

import Foundation
import Alamofire

enum AppError: LocalizedError {
    case notReceipt
    case network
    case server
    case badRequest
    case decoding
    case unknown

    var errorDescription: String? {
        switch self {
        case .notReceipt: return "영수증을 인식하지 못했어요."
        case .network:    return "네트워크 연결을 확인해주세요."
        case .server:     return "잠시 후 다시 시도해주세요."
        case .badRequest: return "요청을 처리하지 못했어요."
        case .decoding:   return "응답을 처리하지 못했어요."
        case .unknown:    return "알 수 없는 오류가 발생했어요."
        }
    }

    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }

        var current: Error? = error
        var responseCode: Int?
        var depth = 0

        while let err = current, depth < 10 {
            depth += 1

            if err is URLError { return .network }
            if (err as NSError).domain == NSURLErrorDomain { return .network }

            if let af = err as? AFError {
                if responseCode == nil { responseCode = af.responseCode }
                current = af.underlyingError
            } else {
                current = nil
            }
        }

        if let code = responseCode {
            switch code {
            case 400..<500: return .badRequest
            case 500..<600: return .server
            default: break
            }
        }

        if error is DecodingError { return .decoding }
        return .unknown
    }
}
