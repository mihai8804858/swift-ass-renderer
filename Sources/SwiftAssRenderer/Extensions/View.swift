import SwiftUI

extension View {
    @ViewBuilder
    func ifLet<ValueContent: View, NoValueContent: View, Value>(
        _ value: @autoclosure () -> Value?,
        transform: (Self, Value) -> ValueContent,
        else noValueTransform: (Self) -> NoValueContent
    ) -> some View {
        if let value = value() {
            transform(self, value)
        } else {
            noValueTransform(self)
        }
    }

    @ViewBuilder
    func ifLet<Content: View, Value>(
        _ value: @autoclosure () -> Value?,
        transform: (Self, Value) -> Content
    ) -> some View {
        ifLet(value(), transform: transform, else: { $0 })
    }

    func readSize(in binding: Binding<CGSize>) -> some View {
        background(SizeReaderView(size: binding))
    }
}

private struct SizeReaderView: View {
    @Binding var size: CGSize

    var body: some View {
        GeometryReader { geometry in
            Color.clear.onAppear {
                size = geometry.frame(in: .local).size
            }.onChange(of: geometry.frame(in: .local).size) { newValue in
                size = newValue
            }
        }
    }
}
