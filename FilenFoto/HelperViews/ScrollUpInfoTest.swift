import SwiftUI

struct Prev: View {
    @State private var showDetails = false
    @State private var translation: CGSize = .zero
    @State private var shouldSHowDetails: Bool = false
    
    @State private var scale: CGFloat = 1.0
    let maxHeight: CGFloat = 300

    var body: some View {
        VStack {
            Image("IMG_3284") // Replace with your image name
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: showDetails ? 300 : 400)
                .clipped()
            //                .onTapGesture {
            //                    withAnimation {
            //                        showDetails.toggle()
            //                    }
            //                }
                .offset(translation)
                .scaleEffect(scale)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            withAnimation {
                                translation = .init(width: 0, height: -maxHeight / 3 >= (value.translation.height + translation.height) ? -maxHeight / 3 : value.translation.height + translation.height)
                                if translation.height < 0 {
                                    shouldSHowDetails = true
                                } else if value.location.y > value.startLocation.y {
                                    shouldSHowDetails = false
                                }
                            }
                        }
                        .onEnded { value in
                            if value.translation.height < 0 {
                                withAnimation {
                                    translation = .init(width: 0, height: -maxHeight / 3)
                                }
                            } else if value.translation.height >= 0 {
                                withAnimation {
                                    shouldSHowDetails = false
                                    translation = .zero
                                }
                            }
                        }
                )
                .sheet(isPresented: .constant(translation.height < 0), onDismiss: {
                    withAnimation {
                        translation = .zero
                    }
                }) {
                    VStack {
                        Spacer()
                        Text("Image Details")
                            .font(.headline)
                            .padding()
                        Text("More details about this image can go here.")
                            .padding(.bottom)
                        Spacer()
                    }
//                    .presentationDetents([.height(abs(translation.height * 3))])
                    .presentationDetents([.height(abs(translation.height * 3) < maxHeight ? abs(translation.height * 3) : maxHeight)])
                    .presentationBackgroundInteraction(
                        .enabled(upThrough: .height(abs(translation.height * 3) < maxHeight ? abs(translation.height * 3) : maxHeight))
                    )
                    .frame(maxWidth: .infinity)
                    .transition(.move(edge: .bottom))
                }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Prev()
    }
}
