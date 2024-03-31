import XCTest
@testable import SwiftAssRenderer

final class FontConfigTests: XCTestCase {
    private var library: OpaquePointer!
    private var renderer: OpaquePointer!
    private var mockFileManager: MockFileManager!
    private var mockBundle: MockBundle!
    private var mockLibraryWrapper: MockLibraryWrapper.Type!

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
        defaultFontFamily: String? = nil
    ) -> FontConfig {
        FontConfig(
            fileManager: mockFileManager,
            moduleBundle: mockBundle,
            libraryWrapper: mockLibraryWrapper,
            fontsPath: fontsPath,
            fontsCachePath: fontsCachePath,
            defaultFontName: defaultFontName,
            defaultFontFamily: defaultFontFamily
        )
    }

    func test_configure_whenCachePathIsMissing_shouldCreateDefaultCacheDirectory() throws {
        // GIVEN
        let fontsPath = URL.downloadsDirectory
        let defaultFontsCachePath = URL.documentsDirectory
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
        let fontsPath = URL.documentsDirectory
        let fontsCachePath = URL.downloadsDirectory
        let config = createConfig(fontsPath: fontsPath, fontsCachePath: fontsCachePath)
        mockFileManager.directoryExistsStub = true

        // WHEN
        try config.configure(library: library, renderer: renderer)

        // THEN
        XCTAssertFalse(mockFileManager.createDirectoryFunc.wasCalled)
    }

    func test_configure_whenCachePathIsPresent_whenCacheDirectoryDoesNotExist_shouldCreateCacheDirectory() throws {
        // GIVEN
        let fontsPath = URL.documentsDirectory
        let fontsCachePath = URL.downloadsDirectory
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
        let fontsPath = URL.downloadsDirectory
        let fontsCachePath = URL.desktopDirectory
        let config = createConfig(fontsPath: fontsPath, fontsCachePath: fontsCachePath)
        mockFileManager.documentsURL = URL.documentsDirectory

        // WHEN
        try config.configure(library: library, renderer: renderer)

        // THEN
        let createFileArgument = try XCTUnwrap(mockFileManager.createItemFunc.argument)
        let expectedDir = fontsPath.path
        let expectedCacheDir = fontsCachePath.appendingPathComponent("fonts-cache").path
        let expectedConfFile = URL.documentsDirectory.appendingPathComponent("fonts.conf")
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
        let fontsPath = URL.documentsDirectory
        let fontsCachePath = URL.downloadsDirectory
        let fontConfPath = URL.documentsDirectory.appendingPathComponent("fonts.conf")
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
        XCTAssert(setFontsArgument == (renderer, fontConfPath.path, defaultFontName, defaultFontFamily))
    }
}
