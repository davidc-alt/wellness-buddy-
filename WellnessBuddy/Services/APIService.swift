//
//  APIService.swift
//  WellnessBuddy
//
//  Connects iOS app to live backend server & Practitioner Studio
//

import Foundation
import Combine

public class APIService: ObservableObject {
    public static let shared = APIService()
    
    // Primary Server URL
    @Published public var baseURLString: String = "https://wellness-buddy-vduz.onrender.com"
    
    // Candidate URLs to try (Live Production Server & Local Dev Server)
    public var candidateURLs: [String] = [
        "https://wellness-buddy-vduz.onrender.com",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://Davids-MacBook-Air-2.local:3000"
    ]
    
    public init() {}
    
    /// Helper to perform HTTP request to live server with retry mechanism for Render cold starts
    private func performRequest(endpoint: String, method: String = "GET", bodyData: Data? = nil, retryCount: Int = 0, completion: @escaping (Data?) -> Void) {
        var urlsToTry = [baseURLString]
        for url in candidateURLs {
            if !urlsToTry.contains(url) {
                urlsToTry.append(url)
            }
        }
        
        func tryNextURL(index: Int) {
            guard index < urlsToTry.count else {
                if retryCount < 2 {
                    print("🔄 APIService: Retrying connection to backend server (attempt \(retryCount + 1))...")
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                        self.performRequest(endpoint: endpoint, method: method, bodyData: bodyData, retryCount: retryCount + 1, completion: completion)
                    }
                    return
                }
                print("⚠️ APIService: All backend server URLs failed.")
                completion(nil)
                return
            }
            
            let base = urlsToTry[index]
            guard let url = URL(string: "\(base)\(endpoint)") else {
                tryNextURL(index: index + 1)
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = method
            // Fast 5s timeout for local server check, 30s for remote cloud server
            request.timeoutInterval = base.hasPrefix("https://") ? 30.0 : 5.0
            if let bodyData = bodyData {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = bodyData
            }
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                if let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode), let data = data {
                    let mimeType = httpResp.mimeType ?? ""
                    let isJson = mimeType.contains("json") || (try? JSONSerialization.jsonObject(with: data)) != nil
                    if isJson {
                        print("✅ APIService: Connected successfully to \(base)\(endpoint)")
                        DispatchQueue.main.async {
                            self?.baseURLString = base
                        }
                        completion(data)
                        return
                    }
                }
                print("🔄 APIService: Failed \(base)\(endpoint), trying next URL/retry...")
                tryNextURL(index: index + 1)
            }.resume()
        }
        
        tryNextURL(index: 0)
    }
    
    /// Client Login via Name & DOB
    /// Restores patient profile, name, DOB, and assigned protocol items to server upon app launch/reconnect
    public func restoreSessionOnServer(
        client: ClientProfile,
        protocolItems: [ProtocolItem] = [],
        completion: @escaping (ClientProfile?, [ProtocolItem]) -> Void
    ) {
        let itemsPayload = protocolItems.map { item -> [String: Any] in
            return [
                "id": item.id.uuidString,
                "name": item.name,
                "brand": item.brand,
                "category": item.category.rawValue,
                "dosageValue": item.dosageValue,
                "dosageUnit": item.dosageUnit.rawValue,
                "timingSchedule": item.timingSchedule.rawValue,
                "frequencyDescription": item.frequencyDescription,
                "intervalHours": item.intervalHoursCalculated,
                "practitionerNotes": item.practitionerNotes,
                "totalServingsRemaining": item.totalServingsRemaining,
                "maxServings": item.maxServings,
                "fullscriptRefillUrl": item.fullscriptRefillUrl ?? "https://us.fullscript.com/welcome/lvitti/signup"
            ]
        }
        
        let payload: [String: Any] = [
            "id": client.id,
            "name": client.name,
            "dob": client.dob ?? "Not specified",
            "email": client.email,
            "goal": client.goal ?? "",
            "symptoms": client.symptoms ?? "None reported",
            "practitionerNote": client.practitionerNote ?? "",
            "items": itemsPayload
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(nil, [])
            return
        }
        
        performRequest(endpoint: "/api/auth/restore-session", method: "POST", bodyData: bodyData) { data in
            guard let data = data else {
                DispatchQueue.main.async { completion(client, protocolItems) }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    var updatedClient = client
                    if let clientDict = json["client"] as? [String: Any],
                       let rawClientData = try? JSONSerialization.data(withJSONObject: clientDict),
                       let decodedClient = try? JSONDecoder().decode(ClientProfile.self, from: rawClientData) {
                        updatedClient = decodedClient
                    }
                    
                    if let rawProtoData = try? JSONSerialization.data(withJSONObject: json["protocolItems"] ?? []),
                       let items = try? JSONDecoder().decode([ProtocolItem].self, from: rawProtoData) {
                        DispatchQueue.main.async { completion(updatedClient, items) }
                        return
                    }
                    DispatchQueue.main.async { completion(updatedClient, protocolItems) }
                    return
                }
                DispatchQueue.main.async { completion(client, protocolItems) }
            } catch {
                print("Restore decode error: \(error)")
                DispatchQueue.main.async { completion(client, protocolItems) }
            }
        }
    }
    
    /// Register New Client via API with Name & DOB
    public func registerClient(name: String, dob: String, email: String, password: String, goal: String, completion: @escaping (ClientProfile?) -> Void) {
        let payload = [
            "name": name,
            "dob": dob,
            "email": email,
            "password": password,
            "goal": goal
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(nil)
            return
        }
        
        performRequest(endpoint: "/api/auth/register-client", method: "POST", bodyData: bodyData) { data in
            guard let data = data else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(LoginClientResponse.self, from: data)
                DispatchQueue.main.async { completion(decoded.client) }
            } catch {
                print("Register decode error: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
    
    /// Fetch protocol items live from backend API for active logged in client
    public func fetchProtocol(for clientId: String, completion: @escaping (PractitionerProtocol?) -> Void) {
        performRequest(endpoint: "/api/protocol/\(clientId)", method: "GET") { data in
            guard let data = data else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(ProtocolResponse.self, from: data)
                let p = decoded.protocolData
                let proto = PractitionerProtocol(
                    title: p.title,
                    practitionerName: p.practitionerName,
                    practitionerTitle: "Integrative Health Specialist",
                    clientName: p.clientName,
                    clientGoal: p.clientGoal,
                    items: p.items,
                    practitionerNoteToClient: p.practitionerNoteToClient,
                    pdfUrl: p.pdfUrl,
                    pdfName: p.pdfName
                )
                DispatchQueue.main.async { completion(proto) }
            } catch {
                print("Decode error: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
    
    /// Post dose log event (Done or Snooze) to backend
    public func logDoseEvent(clientId: String, itemId: UUID, itemName: String, timingSchedule: TimingSchedule, status: DoseStatus) {
        let payload: [String: Any] = [
            "clientId": clientId,
            "itemId": itemId.uuidString,
            "itemName": itemName,
            "timingSchedule": timingSchedule.rawValue,
            "status": status.rawValue
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else { return }
        performRequest(endpoint: "/api/dose-log", method: "POST", bodyData: bodyData) { _ in }
    }
    
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    
    private static let isoFormatterFallback: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Fetch dose logs live from backend API for active logged in client
    public func fetchDoseLogs(for clientId: String, completion: @escaping ([DoseLogEntry]) -> Void) {
        performRequest(endpoint: "/api/dose-log/\(clientId)", method: "GET") { data in
            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(DoseLogListResponse.self, from: data)
                let entries: [DoseLogEntry] = decoded.doseLogs.compactMap { apiItem in
                    let date = APIService.isoFormatter.date(from: apiItem.timestamp) 
                            ?? APIService.isoFormatterFallback.date(from: apiItem.timestamp) 
                            ?? Date()
                    
                    let timing = TimingSchedule(rawValue: apiItem.timingSchedule) ?? .emptyStomach
                    let status = DoseStatus(fromRaw: apiItem.status)
                    let itemId = apiItem.itemId != nil ? apiItem.itemId!.toStableUUID : UUID()
                    let id = apiItem.id.toStableUUID
                    
                    return DoseLogEntry(
                        id: id,
                        itemId: itemId,
                        itemName: apiItem.itemName,
                        timestamp: date,
                        status: status,
                        timingSchedule: timing,
                        note: nil
                    )
                }
                
                DispatchQueue.main.async { completion(entries) }
            } catch {
                print("Dose log decode error: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }
    }
    
    /// Push protocol item to backend for active client
    public func assignProtocolItem(clientId: String, item: ProtocolItem, completion: (() -> Void)? = nil) {
        let itemPayload: [String: Any] = [
            "id": item.id.uuidString,
            "name": item.name,
            "brand": item.brand,
            "category": item.category.rawValue,
            "dosageValue": item.dosageValue,
            "dosageUnit": item.dosageUnit.rawValue,
            "timingSchedule": item.timingSchedule.rawValue,
            "frequencyDescription": item.frequencyDescription,
            "intervalHours": item.intervalHoursCalculated,
            "practitionerNotes": item.practitionerNotes,
            "totalServingsRemaining": item.totalServingsRemaining,
            "maxServings": item.maxServings
        ]
        let payload: [String: Any] = ["item": itemPayload]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else { return }
        performRequest(endpoint: "/api/practitioner/assign-protocol/\(clientId)", method: "POST", bodyData: bodyData) { _ in
            DispatchQueue.main.async { completion?() }
        }
    }
    
    /// Delete protocol item from backend
    public func deleteProtocolItem(clientId: String, itemId: UUID, completion: (() -> Void)? = nil) {
        performRequest(endpoint: "/api/practitioner/delete-protocol-item/\(clientId)/\(itemId.uuidString)", method: "DELETE") { _ in
            DispatchQueue.main.async { completion?() }
        }
    }
    
    /// Delete client profile from backend
    public func deleteClient(clientId: String, completion: (() -> Void)? = nil) {
        performRequest(endpoint: "/api/practitioner/delete-client/\(clientId)", method: "DELETE") { _ in
            DispatchQueue.main.async { completion?() }
        }
    }
    
    /// Fetch practitioner-patient messages
    public func fetchMessages(clientId: String, completion: @escaping ([ChatMessage]) -> Void) {
        performRequest(endpoint: "/api/chat/messages/\(clientId)", method: "GET") { data in
            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(MessagesResponse.self, from: data)
                DispatchQueue.main.async { completion(decoded.messages) }
            } catch {
                DispatchQueue.main.async { completion([]) }
            }
        }
    }
    
    /// Send message to practitioner
    public func sendMessage(clientId: String, senderName: String, text: String, completion: @escaping (Bool) -> Void) {
        let payload: [String: Any] = [
            "sender": "client",
            "senderName": senderName,
            "text": text
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else { return }
        performRequest(endpoint: "/api/chat/send/\(clientId)", method: "POST", bodyData: bodyData) { data in
            DispatchQueue.main.async { completion(data != nil) }
        }
    }
}

// Client Profile API Model
public struct ClientProfile: Codable, Identifiable {
    public var id: String
    public var name: String
    public var dob: String?
    public var email: String
    public var goal: String?
    public var symptoms: String?
    public var practitionerNote: String?
}

struct LoginClientResponse: Codable {
    let success: Bool
    let client: ClientProfile?
    let message: String?
}

struct ProtocolResponse: Codable {
    let success: Bool
    let protocolData: ProtocolPayload
    
    enum CodingKeys: String, CodingKey {
        case success
        case protocolData = "protocol"
    }
}

struct ProtocolPayload: Codable {
    let title: String
    let practitionerName: String
    let clientName: String
    let clientGoal: String
    let practitionerNoteToClient: String
    let pdfUrl: String?
    let pdfName: String?
    let items: [ProtocolItem]
}

public struct ChatMessage: Codable, Identifiable {
    public var id: String
    public var clientId: String
    public var sender: String
    public var senderName: String
    public var text: String
    public var timestamp: String
}

struct MessagesResponse: Codable {
    let success: Bool
    let messages: [ChatMessage]
}

struct DoseLogAPIItem: Codable {
    let id: String
    let clientId: String
    let itemId: String?
    let itemName: String
    let timingSchedule: String
    let status: String
    let timestamp: String
}

struct DoseLogListResponse: Codable {
    let success: Bool
    let doseLogs: [DoseLogAPIItem]
}

