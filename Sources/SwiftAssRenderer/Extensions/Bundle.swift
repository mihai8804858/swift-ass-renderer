import Foundation

protocol BundleType {
    func url(forResource name: String?, withExtension ext: String?) -> URL?
}

extension Bundle: BundleType {}
