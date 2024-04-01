import SwiftLibass

protocol ImagePipelineType {
    func process(image: ASS_Image?) -> ProcessedImage?
}
