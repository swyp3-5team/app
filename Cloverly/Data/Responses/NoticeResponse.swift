//
//  NoticeResponse.swift
//  Cloverly
//
//  Created by 이인호 on 1/4/26.
//

import Foundation

struct NoticeResponse: nonisolated Decodable {
    let totalCount: Int
    let notices: [Notice]
}
