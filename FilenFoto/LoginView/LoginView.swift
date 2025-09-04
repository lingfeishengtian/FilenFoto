//
//  LoginView.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var photoContext: PhotoContext

    @State var username: String = ""
    @State var password: String = ""
    @State var twoFactorCode: String = ""

    @State var isLoading: Bool = false
    @State var errorMessage: String? = nil
    
    @FocusState private var focusedField: UITextContentType?

    func tryLogin() async {
        isLoading = true

        do {
            photoContext.filenClient = try await login(email: username, pwd: password, twoFactorCode: twoFactorCode)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Filen Sign In")
                .font(.largeTitle.weight(.semibold))
                .padding(.bottom, 32)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            LoginField(input: $username, focusedField: $focusedField, textContentType: .username)
            LoginField(input: $password, focusedField: $focusedField, textContentType: .password)
            LoginField(input: $twoFactorCode, focusedField: $focusedField, textContentType: .oneTimeCode)

            Button("Login") {
                Task {
                    await tryLogin()
                }
            }
        }
        .padding()
        .overlay {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2)
                    .padding()
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(10)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(PhotoContext())
}
