import Foundation

/// Which provider to use for character rendering and font management.
public enum FontProvider: Equatable {
    /// Uses [fontconfig](https://www.freedesktop.org/wiki/Software/fontconfig/)
    /// to manage the fonts and render the characters.
    case fontConfig

    /// Uses `CoreText` to render the character using system fonts.
    case coreText
}

protocol FontConfigType {
    func configure(library: OpaquePointer, renderer: OpaquePointer) throws
}

/// Fonts configuration. Defines where the fonts and fonts cache is located,
/// fallbacks for missing fonts and the default `FontProvider` to use.
public struct FontConfig: FontConfigType {
    private static let fontsCacheDirName = "fonts-cache"
    private static let fontsConfFileName = "fonts.conf"

    private let fileManager: FileManagerType
    private let moduleBundle: BundleType
    private let libraryWrapper: LibraryWrapperType.Type
    private let fontsPath: URL
    private let fontsCachePath: URL?
    private let defaultFontName: String?
    private let defaultFontFamily: String?
    private let fontProvider: FontProvider

    /// - Parameters:
    ///   - fontsPath: URL path to fonts directory. Can be read-only.
    ///   - fontsCachePath: URL path to fonts cache directory. 
    ///   The library will append `/fonts-cache` to the `fontsCachePath`.
    ///   If no path is provided, caches directory will be used instead. 
    ///   The `fontsCachePath` should be a **writable** directory.
    ///   - defaultFontName: Default font (file name) from `<fontsPath>` directory.
    ///   This font will be used as fallback when specified fonts in tracks are not found.
    ///   - defaultFontFamily: Default font family.
    ///   This font family will be used as fallback when specified font family in tracks is not found.
    ///   - fontProvider: Default font shaper.
    public init(
        fontsPath: URL,
        fontsCachePath: URL? = nil,
        defaultFontName: String? = nil,
        defaultFontFamily: String? = nil,
        fontProvider: FontProvider = .fontConfig
    ) {
        self.init(
            fileManager: FileManager.default,
            moduleBundle: Bundle.module,
            libraryWrapper: LibraryWrapper.self,
            fontsPath: fontsPath,
            fontsCachePath: fontsCachePath,
            defaultFontName: defaultFontName,
            defaultFontFamily: defaultFontFamily,
            fontProvider: fontProvider
        )
    }

    init(
        fileManager: FileManagerType,
        moduleBundle: BundleType,
        libraryWrapper: LibraryWrapperType.Type,
        fontsPath: URL,
        fontsCachePath: URL?,
        defaultFontName: String?,
        defaultFontFamily: String?,
        fontProvider: FontProvider
    ) {
        self.fileManager = fileManager
        self.moduleBundle = moduleBundle
        self.libraryWrapper = libraryWrapper
        self.fontsPath = fontsPath
        self.fontsCachePath = fontsCachePath
        self.defaultFontName = defaultFontName
        self.defaultFontFamily = defaultFontFamily
        self.fontProvider = fontProvider
    }

    func configure(library: OpaquePointer, renderer: OpaquePointer) throws {
        try makeFontsCacheDirectory()
        try writeFontConfFile()
        configureLibrary(library, renderer: renderer)
    }

    // MARK: - Private

    private var fontsConfPath: URL {
        fileManager.cachesDirectory.appendingPathComponent(FontConfig.fontsConfFileName)
    }

    private var cachePath: URL {
        (fontsCachePath ?? fileManager.cachesDirectory).appendingPathComponent(FontConfig.fontsCacheDirName)
    }

    private func makeFontsCacheDirectory() throws {
        if fileManager.directoryExists(at: cachePath) { return }
        try fileManager.createDirectory(at: cachePath)
    }

    private func configureLibrary(_ library: OpaquePointer, renderer: OpaquePointer) {
        libraryWrapper.setExtractFonts(library, extract: true)
        libraryWrapper.setFonts(
            renderer,
            provider: fontProvider,
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
