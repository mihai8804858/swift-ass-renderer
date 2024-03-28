import Foundation

protocol EnvironmentVariablesType {
    func setValue(_ value: String, forName name: String, override: Bool)
}

struct EnvironmentVariables: EnvironmentVariablesType {
    func setValue(_ value: String, forName name: String, override: Bool) {
        setenv(name, value.cString(using: .utf8), override ? 1 : 0)
    }
}
