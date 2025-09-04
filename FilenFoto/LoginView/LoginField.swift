//
//  LoginField.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/3/25.
//

import SwiftUI

struct LoginField: View {
    @Binding var input: String
    @FocusState.Binding var focusedField: UITextContentType?
    
    let textContentType: UITextContentType
    
    var iconName: String {
        switch textContentType {
        case .username:
            return "person.fill"
        case .password:
            return "lock.fill"
        case .oneTimeCode:
            return "number"
        default:
            return "questionmark"
        }
    }
    
    var placeholder: String {
        switch textContentType {
        case .username:
            return "Email"
        case .password:
            return "Password"
        case .oneTimeCode:
            return "Two Factor Code"
        default:
            return "Input"
        }
    }
    
    var keyboardType: UIKeyboardType {
        switch textContentType {
        case .username:
            return .emailAddress
        case .password:
            return .default
        case .oneTimeCode:
            return .numberPad
        default:
            return .default
        }
    }
    
    @ViewBuilder
    private var inputField: some View {
        if textContentType == .password {
            SecureField(placeholder, text: $input)
        } else {
            TextField(placeholder, text: $input)
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.gray)
            inputField
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($focusedField, equals: textContentType)
            
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(focusedField == textContentType ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
        )
    }
}
