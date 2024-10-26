import SwiftUI

struct NewTestView: View {

    @State private var size: CGRect = .zero

    private var positionDetector: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            Color.clear
                // pre iOS 17: .onChange(of: frame) { newVal in
                .onChange(of: frame) { oldVal, newVal in
                    size = newVal
                }
        }
    }

    private var star: some View {
        GeometryReader { proxy in
            let h = proxy.size.height
            let minY = proxy.frame(in: .global).minY
            Image(systemName: "star")
                .resizable()
                .scaledToFit()
                .opacity(0.2)
                .frame(height: max(h, size.maxY))
                .frame(maxWidth: .infinity)
                .background(Color.yellow)
                .offset(y: min(0, -minY))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Text("y: \(size.minY), height: \(size.height)")
                        .frame(height: 200)
                        .frame(minWidth: 300)
                        .border(.gray)
                        .frame(maxWidth: .infinity)
                }
                .background { positionDetector }
                .background { star }
            }
            .navigationTitle("Navigation Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    NewTestView()
}
