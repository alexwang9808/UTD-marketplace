import SwiftUI

struct AuthenticationView: View {
    @State private var showingSignIn = true
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("UTD Market")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text(showingSignIn ? "Welcome back!" : "Join the community")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                // Toggle between Sign In and Signup
                HStack(spacing: 0) {
                    Button(action: { showingSignIn = true }) {
                        Text("Sign In")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(showingSignIn ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(showingSignIn ? Color.orange : Color.clear)
                    }
                    
                    Button(action: { showingSignIn = false }) {
                        Text("Sign Up")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(!showingSignIn ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(!showingSignIn ? Color.orange : Color.clear)
                    }
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 30)
                
                // Content
                if showingSignIn {
                    SignInView()
                } else {
                    SignUpView()
                }
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}