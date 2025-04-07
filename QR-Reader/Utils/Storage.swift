import Foundation
import RxSwift
import RxRelay

final public class Storage {
    static let shared = Storage(userDefaults: .standard, encoder: JSONEncoder(), decoder: JSONDecoder())
    
    // MARK: - Private properties
    private let queue = DispatchQueue(label: String(describing: Storage.self), qos: .utility)
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var subjects: [String: Any] = [:]
    
    private init(userDefaults: UserDefaults, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
    }
    
    // MARK: - Public methods
    
    /// Returns value in user defaults in case if there is one for current user. Returns nil if not.
    public func stored<T: Codable>(at key: String) -> T? {
        let item: T? = userDefaults.data(forKey: key)
            .flatMap { try? decoder.decode(T.self, from: $0) }
        getSubject(for: key).accept(item)
        return item
    }
    
    /// Store value in user defaults for specific user. Returns the same value (convenience for Signal)
    public func store<T: Codable>(value: T, at key: String) {
        queue.async { [weak self] in
            guard let self else { return }
            if let encoded = try? self.encoder.encode(value) {
                self.userDefaults.set(encoded, forKey: key)
            }
            self.getSubject(for: key).accept(value)
        }
    }
    
    /// Removes any value for specified key at specified scope
    public func remove(at key: String) {
        queue.async { [weak self] in
            self?.userDefaults.set(nil, forKey: key)
        }
    }
    
    /// We need this to ensure the data is written
    public func synchronize() {
        userDefaults.synchronize()
    }
    
    /// Returns an Observable for the specified key
    public func observable<T: Codable>(for key: String) -> Observable<T?> {
        defer { let _: T? = stored(at: key) }
        return getSubject(for: key).asObservable()
    }
    
    // MARK: - Private methods
    
    private func getSubject<T: Codable>(for key: String) -> BehaviorRelay<T?> {
        if let subject = subjects[key] as? BehaviorRelay<T?> {
            return subject
        }
        let subject = BehaviorRelay<T?>(value: nil)
        subjects[key] = subject
        return subject
    }
}

extension Storage {
    var onboardingShown: Bool {
        get {
            let shown: Bool = Storage.shared.stored(at: "onboardingShown") ?? false
            return shown
        }
        set {
            Storage.shared.store(value: newValue, at: "onboardingShown")
        }
    }
}
