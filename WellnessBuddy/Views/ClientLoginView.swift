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
        VStack(spacing: 24) {
            Spacer()
            
            // Header Logo & Branding
            VStack(spacing: 12) {
                WellnessBuddyLogoView(size: 64)
                
                Text("Wellness Buddy")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.paletteDark)
                
                Text("Patient Protocol & Reminder Portal")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.paletteSilver)
            }
            
            // Login Form Box
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("FULL NAME")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.paletteSilver)
                    TextField("Last Name First Name", text: $nameInput)
                        .padding(14)
                        .background(Color.paletteSoftBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("DATE OF BIRTH (MM-DD-YYYY)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.paletteSilver)
                    TextField("MM-DD-YYYY", text: $dobInput)
                        .padding(14)
                        .background(Color.paletteSoftBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("PRIMARY HEALTH GOAL (OPTIONAL)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.paletteSilver)
                    TextField("Primary health goal (optional)...", text: $goalInput)
                        .padding(14)
                        .background(Color.paletteSoftBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
                
                // Submit Button
                Button(action: handleAuth) {
                    if isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Log In & Send DOB to Practitioner")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                }
                .buttonStyle(TactileButtonStyle(backgroundColor: .paletteDark))
                .padding(.top, 8)
            }
            .calmCardStyle(padding: 24, cornerRadius: 26)
            .padding(.horizontal, 20)
            
            // Quick Demo Accounts Chips
            VStack(spacing: 8) {
                Text("QUICK DEMO PATIENT LOGINS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.paletteSilver)
                    .tracking(1.0)
                
                HStack(spacing: 8) {
                    Button("Jhon Doe") {
                        nameInput = "Jhon Doe"
                        dobInput = "1990-01-01"
                        handleAuth()
                    }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.paletteSoftBg)
                    .foregroundColor(.paletteDark)
                    .clipShape(Capsule())
                    
                    Button("Alex Mercer") {
                        nameInput = "Alex Mercer"
                        dobInput = "1992-08-20"
                        handleAuth()
                    }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.paletteSoftBg)
                    .foregroundColor(.paletteDark)
                    .clipShape(Capsule())
                    
                    Button("David Miller") {
                        nameInput = "David Miller"
                        dobInput = "1990-03-10"
                        handleAuth()
                    }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.paletteSoftBg)
                    .foregroundColor(.paletteDark)
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .background(Color.paletteSoftBg.ignoresSafeArea())
    }
    
    private func handleAuth() {
        guard !nameInput.trimmingCharacters(in: .whitespaces).isEmpty,
              !dobInput.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter Full Name and Date of Birth."
            return
        }
        
        NotificationService.shared.requestAuthorization()
        
        isProcessing = true
        errorMessage = nil
        
        APIService.shared.registerClient(
            name: nameInput.trimmingCharacters(in: .whitespaces),
            dob: dobInput.trimmingCharacters(in: .whitespaces),
            email: "",
            password: "",
            goal: goalInput
        ) { client in
            isProcessing = false
            if let client = client {
                viewModel.activeClientProfile = client
                viewModel.activeClientName = client.name
                viewModel.activeClientId = client.id
                viewModel.saveSession(client: client)
                viewModel.isLoggedIn = true
                viewModel.fetchLiveProtocol()
                viewModel.fetchDoseLogs()
            } else {
                errorMessage = "Could not connect to live server. Please tap Log In again while server finishes waking up."
            }
        }
    }
}
