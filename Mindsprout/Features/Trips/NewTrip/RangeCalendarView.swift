import SwiftUI

struct RangeCalendarView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date

    @State private var displayedMonth: Date = Date()
    private let calendar = Calendar.current
    private let weekdaySymbols = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        VStack(spacing: Spacing.sm) {
            monthHeader
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.inkMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            grid
        }
        .onAppear { displayedMonth = startDate }
    }

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold))
            }
            Spacer()
            HStack(spacing: Spacing.sm) {
                Menu {
                    ForEach(1...12, id: \.self) { month in
                        Button(monthName(month)) { setMonth(month) }
                    }
                } label: { dropdown(monthName(calendar.component(.month, from: displayedMonth))) }
                Menu {
                    ForEach(yearRange, id: \.self) { year in
                        Button(String(year)) { setYear(year) }
                    }
                } label: { dropdown(String(calendar.component(.year, from: displayedMonth))) }
            }
            Spacer()
            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right").font(.system(size: 16, weight: .bold))
            }
        }
        .foregroundStyle(AppColor.ink)
        .padding(.horizontal, Spacing.xs)
    }

    private func dropdown(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text).font(AppFont.bodyEmphasized)
            Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(AppColor.ink)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: CornerRadius.small).fill(AppColor.cardSurface.opacity(0.6)))
    }

    private var grid: some View {
        let days = monthDays
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    DayCell(
                        day: calendar.component(.day, from: day),
                        state: state(for: day)
                    )
                    .onTapGesture { select(day) }
                } else {
                    Color.clear.frame(height: 38)
                }
            }
        }
    }

    enum DayState { case normal, start, end, inRange }

    private func state(for day: Date) -> DayState {
        let d = calendar.startOfDay(for: day)
        let s = calendar.startOfDay(for: startDate)
        let e = calendar.startOfDay(for: endDate)
        if d == s { return .start }
        if d == e { return .end }
        if d > s && d < e { return .inRange }
        return .normal
    }

    private func select(_ day: Date) {
        let d = calendar.startOfDay(for: day)
        if d < calendar.startOfDay(for: startDate) || endDate > startDate {
            startDate = d
            endDate = d
        } else {
            endDate = d
        }
    }

    private var monthDays: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start) - 1
        let dayCount = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        var cells: [Date?] = Array(repeating: nil, count: firstWeekday)
        for offset in 0..<dayCount {
            cells.append(calendar.date(byAdding: .day, value: offset, to: interval.start))
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private var yearRange: [Int] {
        let current = calendar.component(.year, from: Date())
        return Array((current - 1)...(current + 3))
    }

    private func monthName(_ month: Int) -> String {
        calendar.shortMonthSymbols[month - 1]
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = next
        }
    }

    private func setMonth(_ month: Int) {
        var comps = calendar.dateComponents([.year, .month, .day], from: displayedMonth)
        comps.month = month
        comps.day = 1
        if let date = calendar.date(from: comps) { displayedMonth = date }
    }

    private func setYear(_ year: Int) {
        var comps = calendar.dateComponents([.year, .month, .day], from: displayedMonth)
        comps.year = year
        comps.day = 1
        if let date = calendar.date(from: comps) { displayedMonth = date }
    }
}

private struct DayCell: View {
    let day: Int
    let state: RangeCalendarView.DayState

    var body: some View {
        Text("\(day)")
            .font(.system(size: 16, weight: isEndpoint ? .bold : .medium, design: .rounded))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(background)
    }

    private var isEndpoint: Bool { state == .start || state == .end }

    private var foreground: Color {
        switch state {
        case .start, .end: return .white
        case .inRange: return AppColor.ink
        case .normal: return AppColor.ink
        }
    }

    @ViewBuilder private var background: some View {
        switch state {
        case .start, .end:
            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                .fill(AppColor.calendarSelected)
        case .inRange:
            Rectangle().fill(AppColor.calendarInRange)
        case .normal:
            Color.clear
        }
    }
}
