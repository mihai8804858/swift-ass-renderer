import Foundation

protocol FontConfigType {
    func configure(library: OpaquePointer, renderer: OpaquePointer) throws
}

public struct FontConfig: FontConfigType {
    private static let fontsDirName = "fonts"
    private static let fontsCacheDirName = "fonts-cache"
    private static let fontsConfFile = (name: "fonts", type: "conf")

    private let fileManager: FileManagerType
    private let moduleBundle: BundleType
    private let libraryWrapper: LibraryWrapperType.Type
    private let environment: EnvironmentVariablesType

    /// URL path to fonts directory.
    ///
    /// Can be read-only.
    ///
    /// - warning: The fonts should be placed in `<fontsPath>/fonts` directory.
    public let fontsPath: URL

    /// URL path to fonts cache directory.
    ///
    /// The library will append `/fonts-cache` to the `fontsCachePath`.
    /// If no path is provided, application documents directory will be instead.
    ///
    /// - warning: The `fontsCachePath` should be a **writable** directory.
    public let fontsCachePath: URL?

    /// Default font (file name) from `<fontsPath>/fonts` directory.
    ///
    /// This font will be used as fallback when specified fonts in tracks are not found in fonts directory.
    public let defaultFontName: String?

    /// Default font family.
    ///
    /// This font family will be used as fallback when specified font family in tracks is not found in fonts directory.
    public let defaultFontFamily: String?

    public init(
        fontsPath: URL,
        fontsCachePath: URL? = nil,
        defaultFontName: String? = nil,
        defaultFontFamily: String? = nil
    ) {
        self.init(
            fileManager: FileManager.default,
            moduleBundle: Bundle.module,
            libraryWrapper: LibraryWrapper.self,
            environment: EnvironmentVariables(),
            fontsPath: fontsPath,
            fontsCachePath: fontsCachePath,
            defaultFontName: defaultFontName,
            defaultFontFamily: defaultFontFamily
        )
    }

    init(
        fileManager: FileManagerType,
        moduleBundle: BundleType,
        libraryWrapper: LibraryWrapperType.Type,
        environment: EnvironmentVariablesType,
        fontsPath: URL,
        fontsCachePath: URL?,
        defaultFontName: String?,
        defaultFontFamily: String?
    ) {
        self.fileManager = fileManager
        self.moduleBundle = moduleBundle
        self.libraryWrapper = libraryWrapper
        self.environment = environment
        self.fontsPath = fontsPath
        self.fontsCachePath = fontsCachePath
        self.defaultFontName = defaultFontName
        self.defaultFontFamily = defaultFontFamily
    }

    func configure(library: OpaquePointer, renderer: OpaquePointer) throws {
        try makeFontsCacheDirectory()
        setFontConfigEnvironment()
        configureLibrary(library, renderer: renderer)
    }

    // MARK: - Private

    private var fontsConfPath: URL? {
        moduleBundle.url(
            forResource: FontConfig.fontsConfFile.name,
            withExtension: FontConfig.fontsConfFile.type
        )
    }

    private var cachePath: URL {
        fontsCachePath ?? fileManager.documentsURL
    }

    private func makeFontsCacheDirectory() throws {
        let fontsCachePath = cachePath.appendingPathComponent(FontConfig.fontsCacheDirName)
        if fileManager.directoryExists(at: fontsCachePath) { return }
        try fileManager.createDirectory(at: fontsCachePath)
    }

    private func setFontConfigEnvironment() {
        environment.setValue(fontsPath.path, forName: "XDG_DATA_HOME", override: false)
        environment.setValue(cachePath.path, forName: "XDG_CACHE_HOME", override: false)
    }

    private func configureLibrary(_ library: OpaquePointer, renderer: OpaquePointer) {
        guard let fontsConfPath else { return }
        libraryWrapper.setExtractFonts(library, extract: true)
        libraryWrapper.setFonts(
            renderer,
            configPath: fontsConfPath.path,
            defaultFont: defaultFontName,
            defaultFamily: defaultFontFamily
        )
    }
}
