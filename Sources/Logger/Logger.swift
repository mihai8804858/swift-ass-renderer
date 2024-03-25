public enum LogLevel: Int {
    case fatal = 0
    case `default` = 5
    case verbose = 7

    public init?(rawValue: Int) {
        switch rawValue {
        case ...0: self = .fatal
        case 1...5: self = .default
        case 6...7: self = .verbose
        default: return nil
        }
    }
}

protocol LoggerType {
    func configureLibrary(_ wrapper: LibraryWrapperType.Type, library: OpaquePointer)
    func log(message: String, messageLevel: LogLevel)
}

struct Logger: LoggerType {
    let level: LogLevel
    let prefix: String

    init(level: LogLevel? = nil, prefix: String = "swift-ass") {
        self.level = level ?? {
            #if DEBUG
            .default
            #else
            .fatal
            #endif
        }()
        self.prefix = prefix
    }

    func configureLibrary(_ wrapper: LibraryWrapperType.Type, library: OpaquePointer) {
        wrapper.setLogCallback(library)
        wrapper.libraryLogger = { messageLevel, message in
            guard let level = LogLevel(rawValue: messageLevel) else { return }
            log(message: message, messageLevel: level)
        }
    }

    func log(message: String, messageLevel: LogLevel) {
        guard level.rawValue >= messageLevel.rawValue else { return }
        print("[\(prefix)] \(message)")
    }
}
