//
//  PractitionerDashboardView.swift
//  WellnessBuddy
//
//  Created for Health Practitioners & Male Clients.
//

import SwiftUI

/// Health Practitioner Portal for creating & assigning custom supplement protocols
public struct PractitionerDashboardView: View {
    @ObservedObject var viewModel: WellnessBuddyViewModel
    
    @State private var showAddItemSheet: Bool = false
    @State private var editingItem: ProtocolItem?
    
    public var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Practitioner Profile Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            WellnessBuddyLogoView(size: 46)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.currentProtocol.practitionerName)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.paletteDark)
                                Text(viewModel.currentProtocol.practitionerTitle)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.paletteSilver)
                            }
                            Spacer()
                            
                            Button(action: {
                                viewModel.isPractitionerMode = false
                                viewModel.triggerToast("Switched to Male Client View")
                            }) {
                                Text("Client View")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Color.paletteSoftBg)
                                    .foregroundColor(.paletteDark)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .calmCardStyle()
                    
                    // Client Selector & Goal Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ACTIVE PATIENT PROTOCOL")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.paletteSilver)
                            .tracking(1.0)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.currentProtocol.clientName)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.paletteDark)
                                Text("Goal: \(viewModel.currentProtocol.clientGoal)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.paletteSilver)
                            }
                            Spacer()
                        }
                    }
                    .calmCardStyle()
                    
                    // Protocol Items Management
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("PRESCRIBED SUPPLEMENTS (\(viewModel.currentProtocol.items.count))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.paletteSilver)
                                .tracking(1.0)
                            Spacer()
                            
                            Button(action: {
                                showAddItemSheet = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Supplement")
                                }
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.paletteSage)
                            }
                        }
                        
                        ForEach(viewModel.currentProtocol.items) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(.paletteDark)
                                    
                                    Text("\(item.dosageValue.cleanString) \(item.dosageUnit.rawValue) • \(item.brand)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.paletteSilver)
                                    
                                    SchedulePillView(schedule: item.timingSchedule, isSelected: false)
                                        .padding(.top, 2)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    editingItem = item
                                }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.paletteDark)
                                }
                            }
                            .calmCardStyle()
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.paletteSoftBg.ignoresSafeArea())
            .navigationTitle("Practitioner Studio")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddItemSheet) {
                AddProtocolItemSheet(viewModel: viewModel)
            }
            .sheet(item: $editingItem) { item in
                EditProtocolItemSheet(item: item, viewModel: viewModel)
            }
        }
    }
}

/// Sheet for Practitioners to add new custom supplement
public struct AddProtocolItemSheet: View {
    @ObservedObject var viewModel: WellnessBuddyViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var category: RegimenCategory = .supplement
    @State private var dosageValue: String = "1"
    @State private var dosageUnit: DosageUnit = .capsules
    @State private var timingSchedule: TimingSchedule = .emptyStomach
    @State private var frequency: String = "Once Daily"
    @State private var selectedIntervalHours: Double = 24.0
    @State private var notes: String = ""
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("General Details")) {
                    TextField("Supplement Name", text: $name)
                    TextField("Brand / Dispensary", text: $brand)
                    
                    Picker("Category", selection: $category) {
                        ForEach(RegimenCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                
                Section(header: Text("Timing Schedule & Dosage")) {
                    Picker("Timing Schedule", selection: $timingSchedule) {
                        ForEach(TimingSchedule.allCases) { timing in
                            Text(timing.rawValue).tag(timing)
                        }
                    }
                    
                    HStack {
                        TextField("Dosage Value", text: $dosageValue)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $dosageUnit) {
                            ForEach(DosageUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                    }
                    
                    Picker("Repeat Frequency / Take Interval", selection: $selectedIntervalHours) {
                        Text("Every 4 Hours").tag(4.0)
                        Text("Every 6 Hours").tag(6.0)
                        Text("Every 8 Hours").tag(8.0)
                        Text("Every 12 Hours").tag(12.0)
                        Text("Every 24 Hours (Once Daily)").tag(24.0)
                        Text("Every 48 Hours (Every 2 Days)").tag(48.0)
                    }
                    
                    TextField("Custom Frequency Label", text: $frequency)
                }
                
                Section(header: Text("Practitioner Notes & Patient Instructions")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Add Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newItem = ProtocolItem(
                            name: name.isEmpty ? "Custom Supplement" : name,
                            brand: brand.isEmpty ? "Standard" : brand,
                            category: category,
                            dosageValue: Double(dosageValue) ?? 1.0,
                            dosageUnit: dosageUnit,
                            timingSchedule: timingSchedule,
                            frequencyDescription: frequency,
                            intervalHours: selectedIntervalHours,
                            practitionerNotes: notes
                        )
                        viewModel.addProtocolItem(newItem)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

/// Sheet for editing existing protocol item
public struct EditProtocolItemSheet: View {
    @State var item: ProtocolItem
    @ObservedObject var viewModel: WellnessBuddyViewModel
    @Environment(\.presentationMode) var presentationMode
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit \(item.name)")) {
                    TextField("Name", text: $item.name)
                    TextField("Brand", text: $item.brand)
                    Picker("Timing Schedule", selection: $item.timingSchedule) {
                        ForEach(TimingSchedule.allCases) { timing in
                            Text(timing.rawValue).tag(timing)
                        }
                    }
                    
                    Picker("Repeat Frequency", selection: Binding(
                        get: { item.intervalHoursCalculated },
                        set: { item.intervalHours = $0; item.frequencyDescription = "Every \($0.cleanString) Hours" }
                    )) {
                        Text("Every 4 Hours").tag(4.0)
                        Text("Every 6 Hours").tag(6.0)
                        Text("Every 8 Hours").tag(8.0)
                        Text("Every 12 Hours").tag(12.0)
                        Text("Every 24 Hours (Once Daily)").tag(24.0)
                        Text("Every 48 Hours (Every 2 Days)").tag(48.0)
                    }
                }
                
                Section(header: Text("Instructions")) {
                    TextEditor(text: $item.practitionerNotes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Edit Supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateProtocolItem(item)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
