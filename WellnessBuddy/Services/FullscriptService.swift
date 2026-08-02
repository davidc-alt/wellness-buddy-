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
    
    @Published public var practitionerDispensaryName: String = "Dr. Marcus Vance Performance Medicine"
    @Published public var practitionerFullscriptUrl: String = "https://fullscript.com/dispensary/dr-vance-performance"
    @Published public var isConnected: Bool = true
    @Published public var lastSyncDate: Date = Date()
    
    public init() {}
    
    /// Generates a direct URL for refilling a specific supplement or peptide protocol item
    public func getRefillUrl(for item: ProtocolItem) -> URL {
        if let customUrl = item.fullscriptRefillUrl, let url = URL(string: customUrl) {
            return url
        }
        
        let encodedName = item.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let defaultUrlString = "\(practitionerFullscriptUrl)?search=\(encodedName)"
        return URL(string: defaultUrlString) ?? URL(string: "https://fullscript.com")!
    }
    
    /// Simulates a 1-tap reorder request via Fullscript API / Dispensary deep-link
    public func reorderItem(_ item: ProtocolItem, servingsToOrder: Int = 30, completion: @escaping (Bool, String) -> Void) {
        // Simulate background network request to Fullscript checkout API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            completion(true, "Refill order submitted to Fullscript for \(item.name) (\(item.brand)). Expected delivery in 2-3 business days.")
        }
    }
}
