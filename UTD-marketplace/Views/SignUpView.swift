import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Signup Form
            VStack(spacing: 16) {
                // Name Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Profile Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .frame(height: 48)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                focusedField = .name
                            }
                        
                        TextField("Enter your profile name", text: $name)
                            .focused($focusedField, equals: .name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .textInputAutocapitalization(.words)
                    }
                }
                
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("UTD Email")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .frame(height: 48)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                focusedField = .email
                            }
                        
                        TextField("utdallas.edu email", text: $email)
                            .focused($focusedField, equals: .email)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                    }
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .frame(height: 48)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                focusedField = .password
                            }
                        
                        SecureField("Create a password", text: $password)
                            .focused($focusedField, equals: .password)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .textContentType(.none)
                            .allowsHitTesting(false)
                    }
                }
                
                // Confirm Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .frame(height: 48)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                focusedField = .confirmPassword
                            }
                        
                        SecureField("Confirm your password", text: $confirmPassword)
                            .focused($focusedField, equals: .confirmPassword)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .textContentType(.none)
                            .allowsHitTesting(false)
                    }
                }
            }
            .padding(.horizontal)
            
            // Error Message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            // Success Message
            if showingSuccess {
                VStack(spacing: 12) {
                    Text("Account Created!")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.2))
                    
                    Text("Verification email sent!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Done") {
                        dismiss()
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.0, green: 0.4, blue: 0.2))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.top, 20)
            } else {
                // Sign Up Button
                Button(action: signUp) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.orange : Color.gray.opacity(0.3))
                    .foregroundColor(isFormValid ? .white : .secondary)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || isLoading)
                .padding(.horizontal)
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        email.hasSuffix("@utdallas.edu") &&
        email.count > "@utdallas.edu".count &&
        !password.isEmpty &&
        password == confirmPassword
    }
    
    private func signUp() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        guard let url = URL(string: "\(AppConfig.baseURL)/auth/signup") else {
            errorMessage = "Invalid server URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let signupData = [
            "email": email,
            "password": password,
            "name": name
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: signupData)
        } catch {
            errorMessage = "Failed to prepare request"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = "Invalid response"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                if httpResponse.statusCode == 201 {
                    // Success
                    showingSuccess = true
                } else {
                    // Parse error message
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        errorMessage = errorResponse.error
                    } catch {
                        errorMessage = "Signup failed"
                    }
                }
            }
        }.resume()
    }
}



#Preview {
    SignUpView()
        .environmentObject(AuthenticationManager())
}
