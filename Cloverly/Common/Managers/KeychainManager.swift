//
//  KeychainManager.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    var accessToken: String? {
        get {
            return read(key: "accessToken")
        }
        set {
            // 값을 넣으면 자동으로 키체인에 저장/삭제
            if let value = newValue {
                create(key: "accessToken", token: value)
            } else {
                delete(key: "accessToken")
            }
        }
    }
    
    var refreshToken: String? {
        get {
            return read(key: "refreshToken")
        }
        set {
            if let value = newValue {
                create(key: "refreshToken", token: value)
            } else {
                delete(key: "refreshToken")
            }
        }
    }
    
    private init() {}
    
    func create(key: String, token: String) {
        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: token.data(using: .utf8, allowLossyConversion: false) as Any
        ]
        
        delete(key: key)
        let status = SecItemAdd(query, nil)
        if status != errSecSuccess {
            print("Keychain create error: \(status)")
        }
    }
    
    func read(key: String) -> String? {
        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue as Any
        ]
        
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess {
            return String(data: item as! Data, encoding: .utf8)
        }
        
        if status == errSecItemNotFound {
            print("Token not found in keychain")
            return nil
        } else {
            print("Error retrieving token from keychain: \(status)")
            return nil
        }
    }
    
    func delete(key: String) {
        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        
        let status = SecItemDelete(query)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Keychain delete error: \(status)")
        }
    }
    
    func save(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        
        KeychainManager.shared.delete(key: "accessToken")
        KeychainManager.shared.create(key: "accessToken", token: accessToken)
        
        KeychainManager.shared.delete(key: "refreshToken")
        KeychainManager.shared.create(key: "refreshToken", token: refreshToken)
    }
}
