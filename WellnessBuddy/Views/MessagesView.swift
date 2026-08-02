//
//  MessagesView.swift
//  WellnessBuddy
//
//  Minimalist Practitioner-Patient Chat Screen for iOS App
//

import SwiftUI

public struct MessagesView: View {
    @ObservedObject var viewModel: WellnessBuddyViewModel
    @State private var chatMessages: [ChatMessage] = []
    @State private var inputMessage: String = ""
    @State private var isLoading: Bool = false
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Practitioner Info Banner
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.paletteDark)
                            .frame(width: 42, height: 42)
                        Text("AT")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.currentProtocol.practitionerName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.paletteDark)
                        Text("Online • Direct Practitioner Chat")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.paletteSage)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.white)
                
                Divider()
                
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(chatMessages) { msg in
                                HStack {
                                    if msg.sender == "client" { Spacer() }
                                    
                                    VStack(alignment: msg.sender == "client" ? .trailing : .leading, spacing: 4) {
                                        Text(msg.text)
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 11)
                                            .background(msg.sender == "client" ? Color.paletteDark : Color.white)
                                            .foregroundColor(msg.sender == "client" ? .white : .paletteDark)
                                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                                        
                                        Text(msg.senderName)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.paletteSilver)
                                            .padding(.horizontal, 4)
                                    }
                                    
                                    if msg.sender != "client" { Spacer() }
                                }
                                .id(msg.id)
                            }
                        }
                        .padding(20)
                    }
                    .background(Color.paletteSoftBg)
                    .onAppear {
                        loadMessages()
                    }
                }
                
                // Input Bar
                HStack(spacing: 10) {
                    TextField("Message Practitioner...", text: $inputMessage)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.paletteSoftBg)
                        .clipShape(Capsule())
                    
                    Button(action: sendMessage) {
                        ZStack {
                            Circle()
                                .fill(Color.paletteDark)
                                .frame(width: 44, height: 44)
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
            }
            .navigationTitle("Practitioner Consultation")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func loadMessages() {
        APIService.shared.fetchMessages(clientId: viewModel.activeClientId) { msgs in
            if !msgs.isEmpty {
                self.chatMessages = msgs
            } else {
                // Fallback default message thread
                self.chatMessages = [
                    ChatMessage(id: "m1", clientId: viewModel.activeClientId, sender: "practitioner", senderName: viewModel.currentProtocol.practitionerName, text: "Welcome! Follow your prescribed timing schedule for maximum supplement absorption.", timestamp: "Today"),
                    ChatMessage(id: "m2", clientId: viewModel.activeClientId, sender: "client", senderName: viewModel.activeClientName, text: "Thanks! Looking forward to starting the regimen.", timestamp: "Today")
                ]
            }
        }
    }
    
    private func sendMessage() {
        let text = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let newMsg = ChatMessage(id: UUID().uuidString, clientId: viewModel.activeClientId, sender: "client", senderName: viewModel.activeClientName, text: text, timestamp: "Just now")
        chatMessages.append(newMsg)
        inputMessage = ""
        
        APIService.shared.sendMessage(clientId: viewModel.activeClientId, senderName: viewModel.activeClientName, text: text) { _ in }
    }
}
