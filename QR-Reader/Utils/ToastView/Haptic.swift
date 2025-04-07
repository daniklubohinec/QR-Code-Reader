import UIKit

protocol ImpactGenerator {
    func generateImpact()
}

final class HapticGenerator: ImpactGenerator {
    static let shared = HapticGenerator()
    
    // MARK: Internal
    private init() { }
    
    func generateImpact() {
        impact.impactOccurred()
    }
    
    // MARK: Fileprivate
    
    fileprivate let impact = UIImpactFeedbackGenerator(style: .light)
}
