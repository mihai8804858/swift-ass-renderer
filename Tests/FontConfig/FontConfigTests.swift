import XCTest
@testable import SwiftAssRenderer

final class FontConfigTests: XCTestCase {
    private var library: OpaquePointer!
    private var renderer: OpaquePointer!
    private var mockFileManager: MockFileManager!
    private var mockBundle: MockBundle!
    private var mockLibraryWrapper: MockLibraryWrapper.Type!

    private var documentsDirectory: URL {
        if #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macOS 13.0, *) {
            URL.documentsDirectory
        } else {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
    }

    private var downloadsDirectory: URL {
        if #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macOS 13.0, *) {
            URL.downloadsDirectory
        } else {
            FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        }
    }

    private var desktopDirectory: URL {
        if #available(iOS 16.0, tvOS 16.0, visionOS 1.0, macOS 13.0, *) {
            URL.desktopDirectory
        } else {
            FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        }
    }

    override func setUp() {
        super.setUp()

        library = OpaquePointer(bitPattern: 1)
        renderer = OpaquePointer(bitPattern: 2)
        mockFileManager = MockFileManager()
        mockBundle = MockBundle()
        mockLibraryWrapper = MockLibraryWrapper.self
    }

    func createConfig(
        fontsPath: URL,
        fontsCachePath: URL? = nil,
        defaultFontName: String? = nil,
        defaultFontFamily: String? = nil,
        fontProvider: FontProvider = .fontConfig
    ) -> FontConfig {
        FontConfig(
            fileManager: mockFileManager,
            moduleBundle: mockBundle,
            libraryWrapper: mockLibraryWrapper,
            fontsPath: fontsPath,
            fontsCachePath: fontsCachePath,
            defaultFontName: defaultFontName,
            defaultFontFamily: defaultFontFamily,
            fontProvider: fontProvider
        )
    }

    func test_configure_whenCachePathIsMissing_shouldCreateDefaultCacheDirectory() throws {
        // GIVEN
        let fontsPath = downloadsDirectory
        let defaultFontsCachePath = documentsDirectory
        let config = createConfig(fontsPath: fontsPath)
        mockFileManager.documentsURL = defaultFontsCachePath
        mockFileManager.directoryExistsStub = false

        // WHEN
        try config.configure(library: library, renderer: renderer)

        // THEN
        let expectedURL = defaultFontsCachePath.appendingPathComponent("fonts-cache")
        XCTAssert(mockFileManager.createDirectoryFunc.wasCalled(with: expectedURL))
    }

    func test_configure_whenCachePathIsPresent_whenCacheDirectoryExists_shouldNotCreateCacheDirectory() throws {
        // GIVEN
        let fontsPath = documentsDirectory
        let fontsCachePath = downloadsDirectory
        let config = createConfig(fontsPath: fontsPath, fontsCachePath: fontsCachePath)
        mockFileManager.directoryExistsStub = true

        // WHEN
        try config.configure(library: library, renderer: renderer)

        // THEN
        XCTAssertFalse(mockFileManager.createDirectoryFunc.wasCalled)
    }

    func test_configure_whenCachePathIsPresent_whenCacheDirectoryDoesNotExist_shouldCreateCacheDirectory() throws {
        // GIVEN
        let fontsPath = documentsDirectory
        let fontsCachePath = downloadsDirectory
        let config = createConfig(fontsPath: fontsPath, fontsCachePath: fontsCachePath)
        mockFileManager.directoryExistsStub = false

        // WHEN
        try config.configure(library: library, renderer: renderer)

        // THEN
        let expectedURL = fontsCachePath.appendingPathComponent("fonts-cache")
        XCTAssert(mockFileManager.createDirectoryFunc.wasCalled(with: expectedURL))
    }

    func test_configure_shouldCreateFontsConfFile() throws {
        // GIVEN
        let fontsPath = downloadsDirectory
        let fontsCachePath = desktopDirectory
        let config = createConfig(fontsPath: fontsPath, fontsCachePath: fontsCachePath)
        mockFileManager.documentsURL = documentsDirectory

        // WHEN
        try config.configure(library: library, renderer: renderer)

        // THEN
        let createFileArgument = try XCTUnwrap(mockFileManager.createItemFunc.argument)
        let expectedDir = fontsPath.path
        let expectedCacheDir = fontsCachePath.appendingPathComponent("fonts-cache").path
        let expectedConfFile = documentsDirectory.appendingPathComponent("fonts.conf")
        let expectedContents = """
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
            <dir>\(expectedDir)</dir>
            <cachedir>\(expectedCacheDir)</cachedir>
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
        XCTAssert(createFileArgument == (expectedConfFile, expectedContents, true))
    }

    func test_configure_shouldSetupFonts() throws {
        // GIVEN
        let fontsPath = documentsDirectory
        let fontsCachePath = downloadsDirectory
        let fontConfPath = documentsDirectory.appendingPathComponent("fonts.conf")
        let defaultFontName = "font.ttf"
        let defaultFontFamily = "Bold"
        let config = createConfig(
            fontsPath: fontsPath,
            fontsCachePath: fontsCachePath,
            defaultFontName: defaultFontName,
            defaultFontFamily: defaultFontFamily
        )

        // WHEN
        try config.configure(library: library, renderer: renderer)

        // THEN
        XCTAssert(mockLibraryWrapper.setExtractFontsFunc.wasCalled)
        XCTAssert(mockLibraryWrapper.setFontsFunc.wasCalled)
        let setExtractFontsArgument = try XCTUnwrap(mockLibraryWrapper.setExtractFontsFunc.argument)
        let setFontsArgument = try XCTUnwrap(mockLibraryWrapper.setFontsFunc.argument)
        XCTAssert(setExtractFontsArgument == (library, true))
        XCTAssert(setFontsArgument == (renderer, .fontConfig, fontConfPath.path, defaultFontName, defaultFontFamily))
    }

    func test_configure_whenUsingCoreText_shouldSetupFonts() throws {
        // GIVEN
        let fontsPath = documentsDirectory
        let fontsCachePath = downloadsDirectory
        let fontConfPath = documentsDirectory.appendingPathComponent("fonts.conf")
        let defaultFontName = "font.ttf"
        let defaultFontFamily = "Bold"
        let config = createConfig(
            fontsPath: fontsPath,
            fontsCachePath: fontsCachePath,
            defaultFontName: defaultFontName,
            defaultFontFamily: defaultFontFamily,
            fontProvider: .coreText
        )

        // WHEN
        try config.configure(library: library, renderer: renderer)

        // THEN
        XCTAssert(mockLibraryWrapper.setExtractFontsFunc.wasCalled)
        XCTAssert(mockLibraryWrapper.setFontsFunc.wasCalled)
        let setExtractFontsArgument = try XCTUnwrap(mockLibraryWrapper.setExtractFontsFunc.argument)
        let setFontsArgument = try XCTUnwrap(mockLibraryWrapper.setFontsFunc.argument)
        XCTAssert(setExtractFontsArgument == (library, true))
        XCTAssert(setFontsArgument == (renderer, .coreText, fontConfPath.path, defaultFontName, defaultFontFamily))
    }
}
