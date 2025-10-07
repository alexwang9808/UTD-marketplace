import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingForgotPassword = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Login Form
            VStack(spacing: 16) {
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter your UTD email", text: $email)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField("Enter your password", text: $password)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .textContentType(.none)
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
            
            // Login Button
            Button(action: login) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Text("Login")
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
            
            // Forgot Password
            Button(action: { showingForgotPassword = true }) {
                Text("Forgot Password?")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.2))
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func login() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        // Create login request
        guard let url = URL(string: "\(AppConfig.baseURL)/auth/login") else {
            errorMessage = "Invalid server URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginData = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
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
                        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                        let authUser = AuthUser(
                            id: loginResponse.user.id,
                            email: loginResponse.user.email,
                            name: loginResponse.user.name,
                            imageUrl: loginResponse.user.imageUrl
                        )
                        
                        // Use AuthenticationManager to handle login
                        authManager.login(token: loginResponse.token, user: authUser)
                        dismiss()
                        
                    } catch {
                        errorMessage = "Failed to process login response"
                    }
                } else {
                    // Parse error message
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        errorMessage = errorResponse.error
                    } catch {
                        errorMessage = "Login failed"
                    }
                }
            }
        }.resume()
    }
}

// Response models
struct LoginResponse: Codable {
    let message: String
    let token: String
    let user: LoginUser
}

struct LoginUser: Codable {
    let id: Int
    let email: String
    let name: String?
    let imageUrl: String?
}

struct ErrorResponse: Codable {
    let error: String
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}