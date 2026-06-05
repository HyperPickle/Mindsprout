//
//  PasswordCheckField.swift
//  MindSprout
//
//  Created by Changrila Souksamlane on 3/6/2026.
//

import SwiftUI
struct PasswordCheckField: View {
    @Binding var text: String
    @FocusState var isActive
    @State var checkMinChars = false
    @State var checkLetter = false
    @State var checkPunctuation = false
    @State var checkNumber = false
    @State var showPassword = false
    var progressColor:Color {
        let containsLetters = text.rangeOfCharacter(from: .letters) != nil
        let containsNumbers = text.rangeOfCharacter(from: .decimalDigits) != nil
        let containsPunctuation = text.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*/")) != nil
        if containsLetters && containsNumbers && containsPunctuation && text.count >= 8{
            return Color.green
        } else if containsLetters && !containsNumbers && !containsPunctuation{
            return Color .red
        } else if containsNumbers && !containsLetters && !containsPunctuation{
            return Color.red
        } else if containsLetters && containsNumbers && !containsPunctuation{
            return Color.yellow
        } else if containsLetters && containsNumbers && containsPunctuation{
            return Color.blue
        } else {
            return Color.white
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 24){
            ZStack(alignment: .leading) {
                SecureField("", text: $text)
                    .foregroundStyle(Color(hex:0x705B4D)) // color typography in the text field
                    .padding(.leading, 10)
                    .frame(width: 350)
                    .frame(height: 55).focused($isActive)
                    .background(Color.white, in: .rect(cornerRadius: 20))
                    .opacity(showPassword ? 0 : 1)
                
                TextField("", text: $text)
                    .foregroundStyle(Color(hex:0x705B4D)) // color typography in the text field
                    .padding(.leading, 10)
                    .frame(width: 350)
                    .frame(height: 55).focused($isActive)
                    .background(Color.white, in: .rect(cornerRadius: 20))
                    .opacity(showPassword ? 1 : 0)
                Text("Password").padding(.leading)
                    .font(.system(size:15, design: .rounded))
                    .foregroundStyle(Color(hex:0x705B4D))
                    .opacity(text.isEmpty ? 1 : 0)
                    .onTapGesture {
                        isActive = true
                    }
                    .onChange(of: text, {oldValue, newValue in
                        withAnimation{
                            checkMinChars = newValue .count >= 8
                            checkLetter = newValue.rangeOfCharacter(from:.letters) != nil
                            checkNumber = newValue.rangeOfCharacter(from:.decimalDigits) != nil
                            checkPunctuation = newValue.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*/")) != nil
                        }
                    })
            }
            .overlay(alignment:.trailing){
                Image (systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding(16)
                    .contentShape(Rectangle())
                    .foregroundStyle(showPassword ? Color(hex:0x705B4D) : Color(hex:0x705B4D))
                    .onTapGesture {
                        showPassword.toggle()
                    }
            }

            VStack(alignment: .leading, spacing: 5) {
                CheckText(text: "Minimum 8 characters", check: $checkMinChars)
                    .font(.system(size:15, design: .rounded))
                CheckText(text: "At least one letter", check: $checkLetter)
                    .font(.system(size:15, design: .rounded))
                CheckText (text:"!@#$%^&*/",check: $checkPunctuation)
                    .font(.system(size:15, design: .rounded))
                CheckText(text:"Number", check: $checkNumber)
                    .font(.system(size:15, design: .rounded))
            }
        }
    }
}
        
#Preview {
    PasswordCheckField(text: .constant(""))
}

struct CheckText: View {
        let text: String
        @Binding var check: Bool
        var body: some View {
            HStack{
                Image(systemName: check ? "checkmark.circle.fill" : "circle")
                    .contentTransition(.symbolEffect)
                Text(text)
                    .foregroundColor(check ? .white : .secondary)
            }
        }
    
}
