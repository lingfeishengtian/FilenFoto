//
//  FanoutView.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/18/24.
//

import SwiftUI

let maxHistory = 5

struct FanOutListView: View {
//    @State private var fanOut = false
    @State private var visibleItems: [Bool]
    @State private var scale: [Bool] = [false, false, false]

    // TODO: temp
    let history: [String]
    let onChangeValueClicked: (String) -> Void

    init(history: [String], onChangeValueClicked: @escaping (String) -> Void) {
        self.history = history
        _visibleItems = State(initialValue: Array(repeating: false, count: maxHistory))
        self.onChangeValueClicked = onChangeValueClicked
    }
    
    func reverseIndex(_ index: Int) -> Int {
        history.count - 1 - index
    }

    var body: some View {
        let enumArray = Array(history.reversed().suffix(3))
        VStack {
            /// more buttons
//            if history.count > enumArray.count && visibleItems[enumArray.count] {
//                HStack {
//                    HStack(spacing: 5) {
//                        ForEach(0..<3) { index in
//                            Text(".")
//                                .scaleEffect(scale[index] ? 1 : 0.8)
//                                .opacity(scale[index] ? 1.0 : 0.3)
//                                .animation(
//                                    Animation.easeInOut(duration: 0.5)
//                                        .delay(Double(index) * 0.2),
//                                    value: scale[index]
//                                )
//                        }
//                    }
//                    .onAppear {
//                        for i in 0..<3 {
//                            withAnimation {
//                                scale[i] = true
//                            }
//                        }
//                    }
//                    .paddedRounded(fill: Color(UIColor.darkGray).opacity(0.7))
//                    .scaleEffect(visibleItems[4] ? 1.0 : 0.1)
//                    .opacity(visibleItems[4] ? 1.0 : 0.0)
//                    .animation(.bouncy, value: visibleItems[4])
//                    Spacer()
//                }.allowsHitTesting(false)
//            }
            ForEach(Array(enumArray.enumerated()), id: \.element.hashValue) { index, histSearch in
                HStack {
                    Button {
                        onChangeValueClicked(histSearch)
                    } label: {
                        Text(histSearch)
                            .paddedRounded(fill: Color(UIColor.darkGray).opacity(0.7))
                            .foregroundStyle(Color.primary)
                    }
                    Spacer()
                }
                .scaleEffect(visibleItems[reverseIndex(index)] ? 1.0 : 0.1)
                .opacity(visibleItems[reverseIndex(index)] ? 1.0 : 0.0)
                .animation(.bouncy, value: visibleItems[reverseIndex(index)])
            }
        }
        .onAppear {
            fanOutSequentially()
        }
    }

    func fanOutSequentially() {
        for (index, _) in visibleItems.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation {
                    visibleItems[index] = true
                }
            }
        }
    }
}

#Preview {
    FanOutListView(history: ["test", "test", "test", "test"], onChangeValueClicked: {_ in })
}
