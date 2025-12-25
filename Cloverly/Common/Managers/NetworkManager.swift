//
//  NetworkManager.swift
//  Cloverly
//
//  Created by 이인호 on 12/25/25.
//

import Foundation
import Alamofire

class NetworkManager {
    static let shared = NetworkManager()
    
    let session: Session = {
        let interceptor = AuthInterceptor()
        return Session(interceptor: interceptor)
    }()
}
