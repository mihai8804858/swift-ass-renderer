import Foundation

protocol FontConfigType {
    func configure(library: OpaquePointer, renderer: OpaquePointer) throws
}

public struct FontConfig: FontConfigType {
    private static let fontsCacheDirName = "fonts-cache"
    private static let fontsConfFileName = "fonts.conf"

    private let fileManager: FileManagerType
    private let moduleBundle: BundleType
    private let libraryWrapper: LibraryWrapperType.Type

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
        fontsPath: URL,
        fontsCachePath: URL?,
        defaultFontName: String?,
        defaultFontFamily: String?
    ) {
        self.fileManager = fileManager
        self.moduleBundle = moduleBundle
        self.libraryWrapper = libraryWrapper
        self.fontsPath = fontsPath
        self.fontsCachePath = fontsCachePath
        self.defaultFontName = defaultFontName
        self.defaultFontFamily = defaultFontFamily
    }

    func configure(library: OpaquePointer, renderer: OpaquePointer) throws {
        try makeFontsCacheDirectory()
        try writeFontConfFile()
        configureLibrary(library, renderer: renderer)
    }

    // MARK: - Private

    private var fontsConfPath: URL {
        fileManager.documentsURL.appendingPathComponent(FontConfig.fontsConfFileName)
    }

    private var cachePath: URL {
        (fontsCachePath ?? fileManager.documentsURL).appendingPathComponent(FontConfig.fontsCacheDirName)
    }

    private func makeFontsCacheDirectory() throws {
        if fileManager.directoryExists(at: cachePath) { return }
        try fileManager.createDirectory(at: cachePath)
    }

    private func configureLibrary(_ library: OpaquePointer, renderer: OpaquePointer) {
        libraryWrapper.setExtractFonts(library, extract: true)
        libraryWrapper.setFonts(
            renderer,
            configPath: fontsConfPath.path,
            defaultFont: defaultFontName,
            defaultFamily: defaultFontFamily
        )
    }

    private func writeFontConfFile() throws {
        try fileManager.createItem(at: fontsConfPath, contents: fontConfContents, override: true)
    }

    private var fontConfContents: String {
        """
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
            <dir>\(fontsPath.path)</dir>
            <cachedir>\(cachePath.path)</cachedir>
            <match target="pattern">
                <test qual="any" name="family">
                    <string>mono</string>
                </test>
                <edit name="family" mode="assign" binding="same">
                    <string>monospace</string>
                </edit>
            </match>
            <match target="pattern">
                <test qual="any" name="family">
                    <string>sans serif</string>
                </test>
                <edit name="family" mode="assign" binding="same">
                    <string>sans-serif</string>
                </edit>
            </match>
            <match target="pattern">
                <test qual="any" name="family">
                    <string>sans</string>
                </test>
                <edit name="family" mode="assign" binding="same">
                    <string>sans-serif</string>
                </edit>
            </match>
            <config>
                <rescan>
                    <int>30</int>
                </rescan>
            </config>
        </fontconfig>
        """
    }
}
