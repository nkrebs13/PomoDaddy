import Foundation

/// In-memory UserDefaults for testing (prevents test pollution)
class MockUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]

    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    override func object(forKey defaultName: String) -> Any? {
        storage[defaultName]
    }

    override func data(forKey defaultName: String) -> Data? {
        storage[defaultName] as? Data
    }

    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }

    override func bool(forKey defaultName: String) -> Bool {
        storage[defaultName] as? Bool ?? false
    }

    override func integer(forKey defaultName: String) -> Int {
        storage[defaultName] as? Int ?? 0
    }

    override func double(forKey defaultName: String) -> Double {
        storage[defaultName] as? Double ?? 0.0
    }

    func clear() {
        storage.removeAll()
    }
}
