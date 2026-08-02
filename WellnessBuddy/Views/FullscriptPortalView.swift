//
//  FullscriptPortalView.swift
//  WellnessBuddy
//
//  Created for Health Practitioners & Male Clients.
//

import SwiftUI
import WebKit

/// Fullscript Integration Hub & Web Checkout Modal View
public struct FullscriptPortalView: View {
    @ObservedObject var viewModel: WellnessBuddyViewModel
    @ObservedObject var fullscriptService = FullscriptService.shared
    
    @State private var selectedItemForRefill: ProtocolItem?
    @State private var isOrderingInProcess: Bool = false
    @State private var orderStatusMessage: String?
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Dispensary Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.calmSage.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "shippingbox.fill")
                                    .foregroundColor(.calmSage)
                                    .font(.system(size: 20))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Fullscript Dispensary")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.calmPine)
                                Text(fullscriptService.practitionerDispensaryName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.calmTextSecondary)
                            }
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("VERIFIED")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Practitioner Direct Discount")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.calmSage)
                                Text("15% auto-applied to all protocol refills")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.calmTextSecondary)
                            }
                            Spacer()
                            Link(destination: URL(string: fullscriptService.practitionerFullscriptUrl)!) {
                                Text("Open Store ↗")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.calmPine)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .calmCardStyle()
                    
                    // Low Stock Alert Banner
                    let lowStockItems = viewModel.currentProtocol.items.filter { $0.isLowStock }
                    if !lowStockItems.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.warmEmber)
                                Text("REFILL RECOMMENDED (\(lowStockItems.count) ITEMS LOW)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.warmEmber)
                            }
                            
                            ForEach(lowStockItems) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(.calmPine)
                                        Text("Only \(item.totalServingsRemaining) servings left in bottle")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.calmTextSecondary)
                                    }
                                    Spacer()
                                    
                                    Button(action: {
                                        triggerFullscriptRefill(for: item)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "cart.fill.badge.plus")
                                            Text("1-Tap Refill")
                                        }
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.warmEmber)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                    }
                                }
                                .padding(10)
                                .background(Color.warmEmber.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .calmCardStyle()
                    }
                    
                    // Complete Protocol Catalog with Refill Triggers
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PROTOCOL REFILL HUB")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.calmTextSecondary)
                            .tracking(1.0)
                        
                        ForEach(viewModel.currentProtocol.items) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(.calmPine)
                                    
                                    Text("\(item.brand) • \(item.dosageValue.cleanString) \(item.dosageUnit.rawValue)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.calmTextSecondary)
                                    
                                    Text("Stock: \(item.totalServingsRemaining) / \(item.maxServings) doses")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundColor(item.isLowStock ? .warmEmber : .calmSage)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    triggerFullscriptRefill(for: item)
                                }) {
                                    Text("Refill")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.calmLightSage)
                                        .foregroundColor(.calmPine)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .calmCardStyle()
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.groundedLinen.ignoresSafeArea())
            .navigationTitle("Fullscript Refills")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedItemForRefill) { item in
                FullscriptCheckoutSheet(item: item, viewModel: viewModel)
            }
        }
    }
    
    private func triggerFullscriptRefill(for item: ProtocolItem) {
        FullscriptService.shared.openFullscriptExternal(for: item)
    }
}

/// Checkout Sheet simulating or deep-linking to Fullscript product page
public struct FullscriptCheckoutSheet: View {
    let item: ProtocolItem
    @ObservedObject var viewModel: WellnessBuddyViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isProcessing: Bool = false
    @State private var orderComplete: Bool = false
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header Banner
                VStack(spacing: 8) {
                    Image(systemName: "shippingbox.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.calmSage)
                    
                    Text("Refill \(item.name)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.calmPine)
                    
                    Text("Prescribed by \(viewModel.currentProtocol.practitionerName)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.calmTextSecondary)
                }
                .padding(.top, 20)
                
                // Item Details Box
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Brand:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.calmTextSecondary)
                        Spacer()
                        Text(item.brand)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.calmPine)
                    }
                    
                    HStack {
                        Text("Dosage & Format:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.calmTextSecondary)
                        Spacer()
                        Text("\(item.dosageValue.cleanString) \(item.dosageUnit.rawValue)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.calmPine)
                    }
                    
                    HStack {
                        Text("Servings:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.calmTextSecondary)
                        Spacer()
                        Text("\(item.maxServings) Doses / 30-Day Supply")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.calmPine)
                    }
                    
                    HStack {
                        Text("Practitioner Price:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.calmTextSecondary)
                        Spacer()
                        Text("$42.50 (15% Off)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.calmSage)
                    }
                }
                .calmCardStyle()
                .padding(.horizontal, 20)
                
                if orderComplete {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        Text("Refill Request Submitted!")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.calmPine)
                        Text("Fullscript auto-ship queued. Stock reset to \(item.maxServings) servings.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.calmTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    if !orderComplete {
                        Button(action: {
                            isProcessing = true
                            FullscriptService.shared.reorderItem(item) { success, msg in
                                isProcessing = false
                                orderComplete = true
                                // Reset servings
                                if let idx = viewModel.currentProtocol.items.firstIndex(where: { $0.id == item.id }) {
                                    viewModel.currentProtocol.items[idx].totalServingsRemaining = item.maxServings
                                }
                            }
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                HStack {
                                    Image(systemName: "bolt.fill")
                                    Text("Confirm 1-Tap Refill via Fullscript")
                                }
                            }
                        }
                        .buttonStyle(TactileButtonStyle(backgroundColor: .calmSage))
                        
                        Link(destination: FullscriptService.shared.getRefillUrl(for: item)) {
                            Text("Open in Fullscript Web Browser ↗")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.calmSage)
                        }
                    } else {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Done")
                        }
                        .buttonStyle(TactileButtonStyle(backgroundColor: .calmPine))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Fullscript Refill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
