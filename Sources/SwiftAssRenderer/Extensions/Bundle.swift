import Foundation

protocol BundleType: Sendable {
    func url(forResource name: String?, withExtension ext: String?) -> URL?
}

extension Bundle: BundleType {}
