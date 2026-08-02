//
//  SupplementTrackerView.swift
//  WellnessBuddy
//
//  Minimalist Supplement Hub matching user palette
//

import SwiftUI

public struct SupplementTrackerView: View {
    @ObservedObject var viewModel: WellnessBuddyViewModel
    
    public var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.paletteOcean)
                            
                            Text("Supplements & Regimens")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.paletteDark)
                        }
                        
                        Text("Detailed breakdown of your custom supplement stack prescribed by your practitioner.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.paletteSilver)
                    }
                    .calmCardStyle()
                    
                    // Prescribed Supplements Catalog
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PRESCRIBED SUPPLEMENT STACK")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.paletteSilver)
                            .tracking(1.0)
                        
                        ForEach(viewModel.currentProtocol.items) { item in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(.paletteDark)
                                        Text("\(item.dosageValue.cleanString) \(item.dosageUnit.rawValue) • \(item.frequencyDescription)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.paletteSilver)
                                    }
                                    Spacer()
                                    
                                    SchedulePillView(schedule: item.timingSchedule, isSelected: false)
                                }
                                
                                if !item.practitionerNotes.isEmpty {
                                    Text(item.practitionerNotes)
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(.paletteDark.opacity(0.8))
                                        .padding(12)
                                        .background(Color.paletteSoftBg)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .calmCardStyle()
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.paletteSoftBg.ignoresSafeArea())
            .navigationTitle("Supplements Hub")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
