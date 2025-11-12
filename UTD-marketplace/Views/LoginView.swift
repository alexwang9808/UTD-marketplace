import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingForgotPassword = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Sign In Form
            VStack(spacing: 16) {
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
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
                        
                        TextField("Enter your UTD email", text: $email)
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
                        
                        SecureField("Enter your password", text: $password)
                            .focused($focusedField, equals: .password)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .textContentType(.none)
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
            
            // Sign In Button
            Button(action: {
                focusedField = nil
                signIn()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.orange : Color.gray.opacity(0.3))
                .foregroundColor(isFormValid ? .white : .secondary)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid || isLoading)
            .padding(.horizontal)
            .animation(nil, value: focusedField)
            
            // Forgot Password
            Button(action: { showingForgotPassword = true }) {
                Text("Forgot Password?")
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func signIn() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        // Create sign in request
        guard let url = URL(string: "\(AppConfig.baseURL)/auth/login") else {
            errorMessage = "Invalid server URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let signInData = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: signInData)
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
                
                if httpResponse.statusCode == 200 {
                    // Success - parse response and store token
                    do {
                        let signInResponse = try JSONDecoder().decode(SignInResponse.self, from: data)
                        let authUser = AuthUser(
                            id: signInResponse.user.id,
                            email: signInResponse.user.email,
                            name: signInResponse.user.name,
                            imageUrl: signInResponse.user.imageUrl
                        )
                        
                        // Use AuthenticationManager to handle sign in
                        authManager.signIn(token: signInResponse.token, user: authUser)
                        dismiss()
                        
                    } catch {
                        errorMessage = "Failed to process sign in response"
                    }
                } else {
                    // Parse error message
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        errorMessage = errorResponse.error
                    } catch {
                        errorMessage = "Sign in failed"
                    }
                }
            }
        }.resume()
    }
}

// Response models
struct SignInResponse: Codable {
    let message: String
    let token: String
    let user: SignInUser
}

struct SignInUser: Codable {
    let id: Int
    let email: String
    let name: String?
    let imageUrl: String?
}

struct ErrorResponse: Codable {
    let error: String
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationManager())
}