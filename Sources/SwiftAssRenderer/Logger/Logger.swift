/// Log level.
public enum LogLevel: Int {
    /// Only fatal errors that result in subtitles not being rendered.
    case fatal = 0

    /// Fatal errors and additional useful information.
    case `default` = 5

    /// All messages
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

/// Log output message and level.
public struct LogMessage {
    /// Output message.
    public let message: String

    /// Output message level.
    public let level: LogLevel
}

/// Where the messages should be send to.
public enum LogOutput {
    /// Print messages to console based on the provided log level.
    case console(LogLevel)

    /// Send all messages to custom handler.
    case custom((LogMessage) -> Void)
}

protocol LoggerType {
    func configureLibrary(_ wrapper: LibraryWrapperType.Type, library: OpaquePointer)
    func log(message: LogMessage)
}

struct Logger: LoggerType {
    let prefix: String
    let output: LogOutput

    init(prefix: String = "swift-ass", output: LogOutput? = nil) {
        self.prefix = prefix
        self.output = output ?? .console({
            #if DEBUG
            .default
            #else
            .fatal
            #endif
        }())
    }

    func configureLibrary(_ wrapper: LibraryWrapperType.Type, library: OpaquePointer) {
        wrapper.setLogCallback(library)
        wrapper.libraryLogger = { messageLevel, message in
            guard let level = LogLevel(rawValue: messageLevel) else { return }
            log(message: LogMessage(message: message, level: level))
        }
    }

    func log(message: LogMessage) {
        let prefixedMessage = "[\(prefix)] \(message.message)"
        switch output {
        case .console(let level):
            guard level.rawValue >= message.level.rawValue else { return }
            print(prefixedMessage)
        case .custom(let log):
            log(LogMessage(message: prefixedMessage, level: message.level))
        }
    }
}
