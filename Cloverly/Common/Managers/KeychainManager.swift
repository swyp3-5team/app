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
    
    private(set) var accessToken: String?
    private(set) var refreshToken: String?
    
    private init() {
        self.accessToken = KeychainManager.shared.read(key: "accessToken")
        self.refreshToken = KeychainManager.shared.read(key: "refreshToken")
    }
    
    func create(key: String, token: String) -> Bool {
        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: token.data(using: .utf8, allowLossyConversion: false) as Any
        ]
        
        let status = SecItemAdd(query, nil)
        guard status == errSecSuccess else {
            print("Keychain create error")
            return false
        }
        return true
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
    
    func delete(key: String) -> Bool {
        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        
        let status = SecItemDelete(query)
        guard status != errSecItemNotFound else {
            print("Token not found in keychain")
            return false
        }
        
        guard status == errSecSuccess else {
            print("Token delete error")
            return false
        }
        
        return true
    }
    
    func save(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        
        _ = KeychainManager.shared.delete(key: "accessToken")
        _ = KeychainManager.shared.create(key: "accessToken", token: accessToken)
        
        _ = KeychainManager.shared.delete(key: "refreshToken")
        _ = KeychainManager.shared.create(key: "refreshToken", token: refreshToken)
    }
}
