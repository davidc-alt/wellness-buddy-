//
//  FullscriptService.swift
//  WellnessBuddy
//
//  Created for Health Practitioners & Male Clients.
//

import Foundation

/// Manages integration with Fullscript practitioner dispensary, order refills, and stock tracking
public class FullscriptService: ObservableObject {
    public static let shared = FullscriptService()
    
    @Published public var practitionerDispensaryName: String = "Practitioner Luba Vitti Integrative Health"
    @Published public var practitionerFullscriptUrl: String = "https://us.fullscript.com/welcome/lvitti/signup"
    @Published public var isConnected: Bool = true
    @Published public var lastSyncDate: Date = Date()
    
    public init() {}
    
    /// Generates a direct URL for refilling a specific supplement or peptide protocol item
    public func getRefillUrl(for item: ProtocolItem? = nil) -> URL {
        if let customUrl = item?.fullscriptRefillUrl, let url = URL(string: customUrl), !customUrl.isEmpty, customUrl != "https://fullscript.com" {
            return url
        }
        return URL(string: "https://us.fullscript.com/welcome/lvitti/signup")!
    }
    
    /// Opens Fullscript dispensary store directly in the device's external web browser
    public func openFullscriptExternal(for item: ProtocolItem? = nil) {
        let url = getRefillUrl(for: item)
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
    
    /// Simulates a 1-tap reorder request via Fullscript API / Dispensary deep-link
    public func reorderItem(_ item: ProtocolItem, servingsToOrder: Int = 30, completion: @escaping (Bool, String) -> Void) {
        openFullscriptExternal(for: item)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(true, "Opening Fullscript in web browser...")
        }
    }
}
