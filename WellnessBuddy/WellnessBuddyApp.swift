//
//  WellnessBuddyApp.swift
//  WellnessBuddy
//
//  Created for Health Practitioners & Male Clients.
//

import SwiftUI
import UserNotifications

@main
struct WellnessBuddyApp: App {
    @StateObject private var viewModel = WellnessBuddyViewModel()
    @StateObject private var notificationService = NotificationService.shared
    
    init() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.paletteSoftBg)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.paletteDark),
            .font: UIFont.systemFont(ofSize: 17, weight: .bold)
        ]
        navAppearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor.white
        tabAppearance.shadowColor = UIColor.black.withAlphaComponent(0.04)
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !viewModel.isLoggedIn && !viewModel.isPractitionerMode {
                    ClientLoginView(viewModel: viewModel)
                } else if viewModel.isPractitionerMode {
                    PractitionerDashboardView(viewModel: viewModel)
                } else {
                    MainTabView(viewModel: viewModel)
                }
            }
            .onAppear {
                viewModel.restoreSessionIfAvailable()
                viewModel.fetchLiveProtocol()
                viewModel.fetchDoseLogs()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    notificationService.requestAuthorization()
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    viewModel.restoreSessionIfAvailable()
                    viewModel.fetchLiveProtocol()
                    viewModel.fetchDoseLogs()
                }
            }
        }
    }
}

/// Main Tab Navigation Container for Client Mode
struct MainTabView: View {
    @ObservedObject var viewModel: WellnessBuddyViewModel
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ClientDashboardView(viewModel: viewModel)
                .tabItem {
                    Label("Protocol", systemImage: "pill.fill")
                }
                .tag(0)
            
            SupplementTrackerView(viewModel: viewModel)
                .tabItem {
                    Label("Supplements", systemImage: "sparkles")
                }
                .tag(1)
            
            ComplianceStatsView(viewModel: viewModel)
                .tabItem {
                    Label("Adherence", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            FullscriptPortalView(viewModel: viewModel)
                .tabItem {
                    Label("Fullscript", systemImage: "shippingbox.fill")
                }
                .tag(3)
        }
        .accentColor(.paletteDark)
    }
}
