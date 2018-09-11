//
// KeychainStore.swift
//
// A Swift wrapper for storing and retrieving `Codable` values from the
// system keychain. The operations are done on a background queue, with
// asynchronous callbacks on the main queue.
//
// Copyright © 2018 Kimmo Kulovesi, https://github.com/arkku/
//

import Foundation
import Security

/// A keychain store for a single `service`.
public struct KeychainStore {
    /// Prepare a keychain store for `service`. All other arguments are optional.
    public init(service: String, accessGroup: String? = nil, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder(), queue: DispatchQueue = DispatchQueue.global()) {
        self.service = service
        self.accessGroup = accessGroup
        self.encoder = encoder
        self.decoder = decoder
        self.queue = queue
    }

    /// The service name in the keychain.
    public let service: String

    /// The (optional) access group in the keychain.
    public let accessGroup: String?

    /// The encoder for storing values.
    let encoder: JSONEncoder

    /// The decoder for retrieving values.
    let decoder: JSONDecoder

    /// The queue on which keychain operations are performed.
    let queue: DispatchQueue

    /// The accessibility level of a keychain item.
    public enum Accessible {
        case always
        case afterFirstUnlock
        case whenUnlocked
        case alwaysThisDeviceOnly
        case whenPasscodeSetThisDeviceOnly
        case afterFirstUnlockThisDeviceOnly
        case whenUnlockedThisDeviceOnly

        var rawValue: CFString {
            switch self {
            case .always:
                return kSecAttrAccessibleAlways
            case .afterFirstUnlock:
                return kSecAttrAccessibleAfterFirstUnlock
            case .whenUnlocked:
                return kSecAttrAccessibleWhenUnlocked
            case .whenPasscodeSetThisDeviceOnly:
                return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            case .whenUnlockedThisDeviceOnly:
                return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            case .afterFirstUnlockThisDeviceOnly:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            case .alwaysThisDeviceOnly:
                return kSecAttrAccessibleAlwaysThisDeviceOnly
            }
        }
    }

    /// Encode and store `value` in the keychain, under `key`.
        public func store<T: Encodable>(_ value: T, forKey key: String, accessible: Accessible, completion: @escaping (Error?) -> Void)  {
        queue.async {
            var encodedValue: Data
            do {
                encodedValue = try self.encoder.encode(value)
            } catch {
                DispatchQueue.main.async { completion(error) }
                return
            }

            var queryAttributes = self.query(forKey: key)
            let storingAttributes: [String: Any] = [
                .valueData: encodedValue,
                .accessible: accessible.rawValue
            ]

            let existingData = self.fetchData(forKey: key)
            var status: OSStatus

            if existingData == nil {
                queryAttributes.merge(storingAttributes) { $1 }
                status = SecItemAdd(queryAttributes as CFDictionary, nil)
            } else {
                status = SecItemUpdate(queryAttributes as CFDictionary, storingAttributes as CFDictionary)
            }
            DispatchQueue.main.async {
                if status == errSecSuccess || status == noErr {
                    completion(nil)
                } else {
                    completion(KeychainError.returnedFailure(existingData == nil ? "SecItemAdd" : "SecItemUpdate", status))
                }
            }
        }
    }

    /// Remove the value for `key` from the keychain.
    public func removeValue(forKey key: String, completion: @escaping (Error?) -> Void) {
        queue.async {
            let queryAttributes = self.query(forKey: key)
            let status = SecItemDelete(queryAttributes as CFDictionary)
            DispatchQueue.main.async {
                switch status {
                case errSecSuccess, errSecItemNotFound, noErr:
                    completion(nil)
                default:
                    completion(KeychainError.returnedFailure("SecItemDelete", status))
                }
            }
        }
    }

    /// Fetch and decode the value of `type` for `key` from the keychain.
    public func fetch<T: Decodable>(_ type: T.Type, forKey key: String, completion: @escaping (T?) -> Void) {
        fetchValue(forKey: key, completion: completion)
    }

    /// Fetch and decode the value for `key` from the keychain.
    public func fetchValue<T: Decodable>(forKey key: String, completion: @escaping (T?) -> Void) {
        queue.async {
            let decodedValue: T?
            if let data = self.fetchData(forKey: key) {
                decodedValue = try? self.decoder.decode(T.self, from: data)
            } else {
                decodedValue = nil
            }
            DispatchQueue.main.async { completion(decodedValue) }
        }
    }

    /// Fetch the raw stored `Data` for `key`. Note that this operation is done
    /// on the calling queue, as this is used internally by operations already
    /// running on `queue`.
    internal func fetchData(forKey key: String) -> Data? {
        var queryAttributes = query(forKey: key)
        queryAttributes[.matchLimit] = kSecMatchLimitOne
        queryAttributes[.returnData] = kCFBooleanTrue
        var result: AnyObject? = nil
        let status = SecItemCopyMatching(queryAttributes as CFDictionary, &result)
        guard (status == errSecSuccess || status == noErr), let data = result as? Data else {
            return nil
        }
        return data
    }

    private func query(forKey key: String) -> [String: Any] {
        var attributes: [String: Any] = [
            .securityClass: kSecClassGenericPassword,
            .service: service,
            .account: key,
        ]
        if let accessGroup = accessGroup {
            attributes[.accessGroup] = accessGroup
        }
        return attributes
    }

    private enum KeychainError: Error, CustomStringConvertible {
        case returnedFailure(String, OSStatus)

        var description: String {
            switch self {
            case .returnedFailure(let operation, let status):
                return "\(operation) returned error \(status)"
            }
        }
    }
}

fileprivate extension String {
    static let securityClass = kSecClass as String
    static let service = kSecAttrService as String
    static let valueData = kSecValueData as String
    static let account = kSecAttrAccount as String
    static let accessible = kSecAttrAccessible as String
    static let accessGroup = kSecAttrAccessGroup as String
    static let matchLimit = kSecMatchLimit as String
    static let returnData = kSecReturnData as String
}
