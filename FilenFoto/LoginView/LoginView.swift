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
        VStack {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Two Factor Code", text: $twoFactorCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Login") {
                Task {
                    await tryLogin()
                }
            }
        }.overlay {
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
}
