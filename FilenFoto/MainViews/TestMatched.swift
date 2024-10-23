import SwiftUI

struct MatchedGeometryScrollOffsetExample: View {
    @Namespace private var animation
    @State private var selected: Bool = false
    @State private var scrollOffset: CGFloat = 0.0

    var body: some View {
        ScrollView {
            VStack {
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            scrollOffset = geo.frame(in: .global).minY
                        }
                        .onChange(of: geo.frame(in: .global).minY) { newOffset in
                            withAnimation {
                                scrollOffset = newOffset
                            }
                        }
                        .scaleEffect(scrollOffset + 1.0)
                }
                .frame(height: 0) // Tracking the scroll offset without showing any content

                VStack(spacing: 20) {
                    if !selected {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 100)
                            .matchedGeometryEffect(id: "rect", in: animation)
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    selected.toggle()
                                }
                            }
                    }

                    ForEach(0..<10) { index in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray)
                            .frame(height: 150)
                            .overlay(Text("Item \(index)").foregroundColor(.white))
                            .offset(y: scrollOffset * 0.1) // Adjust position based on scroll offset
                    }

                    if selected {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 300, height: 300)
                            .matchedGeometryEffect(id: "rect", in: animation)
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    selected.toggle()
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct MatchedGeometryScrollOffsetExample_Previews: PreviewProvider {
    static var previews: some View {
        MatchedGeometryScrollOffsetExample()
    }
}
