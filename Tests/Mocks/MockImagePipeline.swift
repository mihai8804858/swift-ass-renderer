import SwiftLibass
@testable import SwiftAssRenderer

final class MockImagePipeline: ImagePipelineType {
    let processFunc = FuncCheck<ASS_Image>()
    var processStub: ProcessedImage?
    func process(image: ASS_Image) -> ProcessedImage? {
        processFunc.call(image)
        return processStub
    }
}
