//
//  CalendarSelection.swift
//  MindSprout
//
//  Created by Changrila Souksamlane on 4/6/2026.
//

import SwiftUI

struct DateRangePickerView: View {
    @Binding var showCalendar: Bool
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @State private var currentMonth = Date()
    
    var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        if let start = startDate, let end = endDate {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else if let start = startDate {
            return "\(formatter.string(from: start)) - ?"
        }
        return "Select dates"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Button {
                withAnimation(.spring()) {
                    showCalendar.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color(hex: 0x5C6A6E))
                    Text(dateRangeText)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(hex: 0x5C6A6E))
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.8), in: .rect(cornerRadius: CornerRadius.medium))
            }
        }
    }
}

struct CalendarView: View {
    @Binding var currentMonth: Date
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    
    let calendar = Calendar.current
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    let weekDays = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: currentMonth)
    }
    
    var yearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: currentMonth)
    }
    
    var days: [Date?] {
        guard let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: currentMonth)
        ) else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: monthStart) - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!.count
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        return days
    }
    
    func isSelected(_ date: Date) -> Bool {
        if let start = startDate, calendar.isDate(date, inSameDayAs: start) { return true }
        if let end = endDate, calendar.isDate(date, inSameDayAs: end) { return true }
        return false
    }
    
    func isInRange(_ date: Date) -> Bool {
        guard let start = startDate, let end = endDate else { return false }
        return date > start && date < end
    }
    
    func selectDate(_ date: Date) {
        if startDate == nil || (startDate != nil && endDate != nil) {
            startDate = date
            endDate = nil
        } else if let start = startDate, date > start {
            endDate = date
        } else {
            startDate = date
            endDate = nil
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            
            // NAVIGATE BETWEEN MONTH
            HStack {
                Button {
                    currentMonth = calendar.date(
                        byAdding: .month, value: -1, to: currentMonth
                    ) ?? currentMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color(hex:0x5C6A6E))
                }
                
                Spacer()
                
                // PICK MONTH OR YEAR
                HStack(spacing: 8) {
                    Menu(monthTitle) {
                        ForEach(1...12, id: \.self) { month in
                            Button(DateFormatter().monthSymbols[month - 1]) {
                                var components = calendar.dateComponents([.year, .month], from: currentMonth)
                                components.month = month
                                currentMonth = calendar.date(from: components) ?? currentMonth
                            }
                        }
                    }
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: 0x000000))
                    
                    Menu(yearTitle) {
                        ForEach(2024...2030, id: \.self) { year in
                            Button(String(year)) {
                                var components = calendar.dateComponents([.year, .month], from: currentMonth)
                                components.year = year
                                currentMonth = calendar.date(from: components) ?? currentMonth
                            }
                        }
                    }
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: 0x000000))

                }
                
                Spacer()
                
                Button {
                    currentMonth = calendar.date(
                        byAdding: .month, value: 1, to: currentMonth
                    ) ?? currentMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color(hex:0x5C6A6E))
                }
            }
            .padding(.horizontal)
            
            // WEEKDAYS
            LazyVGrid(columns: columns) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(hex: 0x757575))
                }
            }
            
            // DAYS
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<days.count, id: \.self) { index in
                    if let date = days[index] {
                        let day = calendar.component(.day, from: date)
                        let selected = isSelected(date)
                        let inRange = isInRange(date)
                        let isPast = date < calendar.startOfDay(for: Date())
                        
                        Text("\(day)")
                            .font(.system(size: 15, weight: selected ? .bold : .regular, design: .rounded))
                            .foregroundStyle(
                                isPast ? Color.gray.opacity(0.4) :
                                selected ? Color.white :
                                inRange ? Color.black : Color.black
                            )
                            .frame(width: 36, height: 36)
                            .background(
                                selected ? Color.black :
                                inRange ? Color.gray.opacity(0.15) :
                                Color.clear,
                                in: .rect(cornerRadius: 5)
                            )
                            .onTapGesture {
                                if !isPast { selectDate(date) }
                            }
                    } else {
                        Text("")
                            .frame(width: 36, height: 36)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .padding(.top, 16)
    }
}

#Preview {
    ZStack {
        BackgroundSky()
        DateRangePickerView(
            showCalendar: .constant(true), startDate: .constant(nil),
            endDate: .constant(nil)
        )
    }
        
}
