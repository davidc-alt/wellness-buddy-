//
//  PeptideTrackerView.swift
//  WellnessBuddy
//
//  Minimalist Peptide & Bioregulator View matching user palette
//

import SwiftUI

public struct PeptideTrackerView: View {
    @ObservedObject var viewModel: WellnessBuddyViewModel
    
    @State private var inputVialMg: String = "5.0"
    @State private var inputBacWaterMl: String = "2.0"
    @State private var inputTargetMcg: String = "250"
    
    public var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "syringe.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.paletteOcean)
                            
                            Text("Peptides & Bioregulators")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.paletteDark)
                        }
                        
                        Text("Calculate syringe units, reconstitution ratios, and log injection site rotations.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.paletteSilver)
                    }
                    .calmCardStyle()
                    
                    // Injection Site Rotation Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("INJECTION SITE ROTATION")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.paletteSilver)
                            .tracking(1.0)
                        
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.paletteSoftBg)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "cross.case.fill")
                                    .foregroundColor(.paletteDark)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Last Recorded Site:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.paletteSilver)
                                Text(viewModel.lastInjectionSite)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.paletteDark)
                            }
                            Spacer()
                        }
                        
                        Text("Select Next Rotation Site:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.paletteDark)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.peptideRotations, id: \.self) { site in
                                    Button(action: {
                                        viewModel.lastInjectionSite = site
                                        viewModel.triggerToast("Updated site to \(site)")
                                    }) {
                                        Text(site)
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(viewModel.lastInjectionSite == site ? Color.paletteDark : Color.paletteSoftBg)
                                            .foregroundColor(viewModel.lastInjectionSite == site ? .white : .paletteDark)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .calmCardStyle()
                    
                    // Reconstitution & Syringe Calculator Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "function")
                                .foregroundColor(.paletteDark)
                            Text("Reconstitution Calculator")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.paletteDark)
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Vial Quantity (mg):")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.paletteDark)
                                Spacer()
                                TextField("5.0", text: $inputVialMg)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                            }
                            
                            HStack {
                                Text("BAC Water (mL):")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.paletteDark)
                                Spacer()
                                TextField("2.0", text: $inputBacWaterMl)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                            }
                            
                            HStack {
                                Text("Target Dose (mcg):")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.paletteDark)
                                Spacer()
                                TextField("250", text: $inputTargetMcg)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                            }
                        }
                        
                        // Output Display Box
                        let units = calculateSyringeUnits()
                        VStack(spacing: 6) {
                            Text("SYRINGE DOSAGE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .tracking(1.0)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(String(format: "%.1f", units))
                                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Units (U-100)")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Text("Equals \(String(format: "%.2f", units / 100.0)) mL injection volume")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.paletteDark)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .calmCardStyle()
                    
                    // Prescribed Peptides List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PRESCRIBED PEPTIDES")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.paletteSilver)
                            .tracking(1.0)
                        
                        let peptides = viewModel.currentProtocol.items.filter { $0.category == .peptide }
                        
                        ForEach(peptides) { item in
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
                                
                                if let units = item.calculatedSyringeUnits {
                                    HStack {
                                        Image(systemName: "circle.circle.fill")
                                            .foregroundColor(.paletteOcean)
                                            .font(.system(size: 12))
                                        Text("Draw \(String(format: "%.1f", units)) units on insulin syringe")
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundColor(.paletteOcean)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.paletteOcean.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                            .calmCardStyle()
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.paletteSoftBg.ignoresSafeArea())
            .navigationTitle("Peptide Hub")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func calculateSyringeUnits() -> Double {
        guard let mg = Double(inputVialMg), let ml = Double(inputBacWaterMl), let mcg = Double(inputTargetMcg), mg > 0, ml > 0 else {
            return 0.0
        }
        let totalMcgInVial = mg * 1000.0
        let mcgPerMl = totalMcgInVial / ml
        let mlPerDose = mcg / mcgPerMl
        return mlPerDose * 100.0
    }
}
