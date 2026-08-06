//
//  ClientLoginView.swift
//  WellnessBuddy
//
//  Minimalist Client Login & Registration Screen for iOS App
//  Allows logging in / registering with Full Name and Date of Birth (DOB)
//

import SwiftUI

public struct ClientLoginView: View {
    @ObservedObject var viewModel: WellnessBuddyViewModel
    
    @State private var nameInput: String = ""
    @State private var dobInput: String = ""
    @State private var goalInput: String = ""
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Spacer(minLength: 40)
                
                // Header Logo & Branding
                VStack(spacing: 14) {
                    WellnessBuddyLogoView(size: 68)
                    
                    Text("Wellness Buddy")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.paletteDark)
                    
                    Text("Patient Protocol & Reminder Portal")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.paletteSilver)
                }
                
                // Login Form Card
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FULL NAME")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.paletteSilver)
                            .tracking(0.8)
                        
                        TextField("Full Name (e.g. John Doe)", text: $nameInput)
                            .padding(15)
                            .background(Color.paletteSoftBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DATE OF BIRTH (MM-DD-YYYY)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.paletteSilver)
                            .tracking(0.8)
                        
                        TextField("MM-DD-YYYY", text: $dobInput)
                            .padding(15)
                            .background(Color.paletteSoftBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PRIMARY HEALTH GOAL (OPTIONAL)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.paletteSilver)
                            .tracking(0.8)
                        
                        TextField("e.g. Optimize energy & recovery", text: $goalInput)
                            .padding(15)
                            .background(Color.paletteSoftBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                    
                    // Submit Button
                    Button(action: handleAuth) {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                                .frame(height: 22)
                        } else {
                            Text("Log In / Register")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                    }
                    .buttonStyle(TactileButtonStyle(backgroundColor: .paletteDark))
                    .padding(.top, 10)
                    .disabled(isProcessing)
                }
                .calmCardStyle(padding: 24, cornerRadius: 28)
                .padding(.horizontal, 22)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color.paletteSoftBg.ignoresSafeArea())
    }
    
    private func handleAuth() {
        let trimmedName = nameInput.trimmingCharacters(in: .whitespaces)
        let trimmedDob = dobInput.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedName.isEmpty, !trimmedDob.isEmpty else {
            withAnimation(.easeOut(duration: 0.2)) {
                errorMessage = "Please enter your Full Name and Date of Birth."
            }
            return
        }
        
        NotificationService.shared.requestAuthorization()
        
        withAnimation(.easeOut(duration: 0.2)) {
            isProcessing = true
            errorMessage = nil
        }
        
        APIService.shared.registerClient(
            name: trimmedName,
            dob: trimmedDob,
            email: "",
            password: "",
            goal: goalInput
        ) { client in
            withAnimation(.easeOut(duration: 0.25)) {
                isProcessing = false
                if let client = client {
                    viewModel.activeClientProfile = client
                    viewModel.activeClientName = client.name
                    viewModel.activeClientId = client.id
                    viewModel.saveSession(client: client)
                    viewModel.isLoggedIn = true
                    viewModel.startLivePolling()
                    viewModel.fetchLiveProtocol()
                    viewModel.fetchDoseLogs()
                    APIService.shared.restoreSessionOnServer(client: client, protocolItems: []) { _, _ in }
                } else {
                    errorMessage = "Could not connect to server. Please check connection and try again."
                }
            }
        }
    }
}
