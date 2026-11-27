import Testing

/// Parent of every suite that uses `MockLibraryWrapper`. The mock's stubs and call
/// records are static, so these tests share them and must run one at a time.
@Suite(.serialized)
enum MockLibraryWrapperSuites {}
