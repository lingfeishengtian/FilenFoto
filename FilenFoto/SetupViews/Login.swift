//
//  LoginSetupDirectories.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/14/24.
//

import SwiftUI
import FilenSDK

struct Login: View {
    @State private var isAnimating = false
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var twoFactorCode: String = ""
    @State private var shouldShowTwoFactor: Bool = false
    
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    @Binding public var isLoggedIn: Bool
    
    func attemptLogin() async {
        let client = FilenClient(tempPath: FileManager.default.temporaryDirectory)
        do {
            try await client.login(email: username, password: password, twoFactorCode: twoFactorCode)
            saveUserDefaultConfig(client: client)
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            shouldShowTwoFactor = true
        }
    }
    
    var body: some View {
        QuickLoadingView (isLoading: isLoading) {
            VStack {
                Text("Login to Filen")
                    .font(isAnimating ? .largeTitle : .largeTitle)
                    .bold()
                    .animation(.easeInOut(duration: 1), value: isAnimating)
                if (!errorMessage.isEmpty) {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                TextField("E-Mail", text: $username)
                    .paddedRounded(fill: Color.gray.opacity(0.25))
                SecureField("Password", text: $password)
                    .paddedRounded(fill: Color.gray.opacity(0.25))
                if (shouldShowTwoFactor) {
                    TextField("Two-Factor", text: $twoFactorCode)
                        .paddedRounded(fill: Color.gray.opacity(0.25))
                }
                Button(action: {
                    isLoading = true
                    Task {
                        await attemptLogin()
                    }
                }) {
                    Text("Sign In")
                        .fontWeight(.heavy)
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(LinearGradient(gradient: Gradient(colors: [.purple, .pink.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(40)
                        .padding([.leading, .trailing])
                        .padding([.top])
                }
            }
            .onAppear() {
                isAnimating = true
            }
            .padding()
            .blur(radius: isLoading ? 3 : 0)
        }
    }
}

extension View {
    func paddedRounded(fill: Color) -> some View {
        self.padding()
            .background(Color.gray.opacity(0.25))
            .cornerRadius(15)
            .padding([.leading, .trailing])
    }
}

#Preview {
    Login(isLoggedIn: Binding(get: {
        false
    }, set: { _ in
        return
    }))
}
