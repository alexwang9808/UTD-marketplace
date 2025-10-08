import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var showingSuccess = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your UTD email address and we'll send you a link to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Email Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter your UTD email", text: $email)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
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
                .padding(.horizontal)
                
                // Message
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(showingSuccess ? Color(red: 0.0, green: 0.4, blue: 0.2) : .red)
                        .padding(.horizontal)
                }
                
                // Send Reset Button
                Button(action: sendResetEmail) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Text("Send Reset Link")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isEmailValid ? Color.orange : Color.gray.opacity(0.3))
                    .foregroundColor(isEmailValid ? .white : .secondary)
                    .cornerRadius(12)
                }
                .disabled(!isEmailValid || isLoading)
                .padding(.horizontal)
                
                if showingSuccess {
                    VStack(spacing: 16) {
                        Text("Check your email")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("We've sent password reset instructions to your email address.")
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
                }
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isEmailValid: Bool {
        email.hasSuffix("@utdallas.edu") && email.count > "@utdallas.edu".count
    }
    
    private func sendResetEmail() {
        guard isEmailValid else { return }
        
        isLoading = true
        message = ""
        showingSuccess = false
        
        guard let url = URL(string: "\(AppConfig.baseURL)/auth/forgot-password") else {
            message = "Invalid server URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestData = ["email": email]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            message = "Failed to prepare request"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    message = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      let data = data else {
                    message = "Invalid response"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode([String: String].self, from: data)
                    
                    if httpResponse.statusCode == 200 {
                        message = response["message"] ?? "Reset email sent"
                        showingSuccess = true
                    } else {
                        message = response["error"] ?? "Failed to send reset email"
                    }
                } catch {
                    message = "Failed to process response"
                }
            }
        }.resume()
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthenticationManager())
}