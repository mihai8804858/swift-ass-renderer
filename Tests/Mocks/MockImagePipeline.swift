import CoreGraphics
import SwiftLibass
import SwiftAssBlend
@testable import SwiftAssRenderer

final class MockImagePipeline: ImagePipelineType {
    let processFunc = FuncCheck<([ASS_Image], CGRect)>()
    nonisolated(unsafe) var processStub: ProcessedImage?
    func process(images: [ASS_Image], boundingRect: CGRect) -> ProcessedImage? {
        processFunc.call((images, boundingRect))
        return processStub
    }
}
