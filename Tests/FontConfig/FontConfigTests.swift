import XCTest
@testable import SwiftAssRenderer

final class FontConfigTests: XCTestCase {
    private var library: OpaquePointer!
    private var renderer: OpaquePointer!
    private var mockFileManager: MockFileManager!
    private var mockBundle: MockBundle!
    private var mockLibraryWrapper: MockLibraryWrapper.Type!
    private var mockEnvironment: MockEnvironment!

    override func setUp() {
        super.setUp()

        library = OpaquePointer(bitPattern: 1)
        renderer = OpaquePointer(bitPattern: 2)
        mockFileManager = MockFileManager()
        mockBundle = MockBundle()
        mockLibraryWrapper = MockLibraryWrapper.self
        mockEnvironment = MockEnvironment()
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
            environment: mockEnvironment,
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

    func test_configure_whenCachePathIsMissing_shouldSetDefaultPathsEnvironment() throws {
        // GIVEN
        let fontsPath = URL.downloadsDirectory
        let defaultFontsCachePath = URL.documentsDirectory
        let config = createConfig(fontsPath: fontsPath)
        mockFileManager.documentsURL = defaultFontsCachePath

        // WHEN
        try config.configure(library: library, renderer: renderer)

        // THEN
        let arguments = [
            (fontsPath.path, "XDG_DATA_HOME", false),
            (defaultFontsCachePath.path, "XDG_CACHE_HOME", false)
        ]
        zip(arguments, mockEnvironment.setValueFunc.arguments).forEach { XCTAssert($0 == $1) }
    }

    func test_configure_whenCachePathIsPresent_shouldSetPathsEnvironment() throws {
        // GIVEN
        let fontsPath = URL.documentsDirectory
        let fontsCachePath = URL.downloadsDirectory
        let config = createConfig(fontsPath: fontsPath, fontsCachePath: fontsCachePath)

        // WHEN
        try config.configure(library: library, renderer: renderer)

        // THEN
        let arguments = [
            (fontsPath.path, "XDG_DATA_HOME", false),
            (fontsCachePath.path, "XDG_CACHE_HOME", false)
        ]
        zip(arguments, mockEnvironment.setValueFunc.arguments).forEach { XCTAssert($0 == $1) }
    }

    func test_configure_whenFontConfPathIsMissing_shouldNotSetupFonts() throws {
        // GIVEN
        let fontsPath = URL.documentsDirectory
        let fontsCachePath = URL.downloadsDirectory
        let config = createConfig(fontsPath: fontsPath, fontsCachePath: fontsCachePath)
        mockBundle.urlStub = nil

        // WHEN
        try config.configure(library: library, renderer: renderer)

        // THEN
        XCTAssertFalse(mockLibraryWrapper.setExtractFontsFunc.wasCalled)
        XCTAssertFalse(mockLibraryWrapper.setFontsFunc.wasCalled)
    }

    func test_configure_whenFontConfPathIsPresent_shouldSetupFonts() throws {
        // GIVEN
        let fontsPath = URL.documentsDirectory
        let fontsCachePath = URL.downloadsDirectory
        let fontConfPath = URL.homeDirectory
        let defaultFontName = "font.ttf"
        let defaultFontFamily = "Bold"
        let config = createConfig(
            fontsPath: fontsPath,
            fontsCachePath: fontsCachePath,
            defaultFontName: defaultFontName,
            defaultFontFamily: defaultFontFamily
        )
        mockBundle.urlStub = fontConfPath

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
