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
                        .foregroundStyle(AppColor.secondaryLabel)
                        .frame(maxWidth: .infinity)
                }
            }
            grid
        }
        .onAppear { displayedMonth = startDate }
    }

    private var monthHeader: some View {
        HStack {
            calendarControlButton(systemName: "chevron.left") { shiftMonth(-1) }
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
            calendarControlButton(systemName: "chevron.right") { shiftMonth(1) }
        }
        .foregroundStyle(AppColor.label)
        .padding(.horizontal, Spacing.xs)
    }

    private func dropdown(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text).font(AppFont.bodyEmphasized)
            Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(AppColor.label)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background {
            Color.clear.tripGlassSurface(
                style: .neutral,
                in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
            )
        }
    }

    private func calendarControlButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColor.label)
                .frame(width: 36, height: 36)
                .background {
                    Color.clear.tripGlassSurface(
                        style: .neutral,
                        in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    )
                }
        }
    }

    private var grid: some View {
        let days = monthDays
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    DayCell(
                        day: calendar.component(.day, from: day),
                        state: state(for: day),
                        isSingleSelection: calendar.startOfDay(for: startDate) == calendar.startOfDay(for: endDate)
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
    var isSingleSelection: Bool = false

    private static let selectionLineWidth: CGFloat = 2

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("\(day)")
            .font(isEndpoint ? AppFont.bodyEmphasized : AppFont.body)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(background)
    }

    private var isEndpoint: Bool { state == .start || state == .end }

    private var foreground: Color {
        switch state {
        case .start, .end:
            return .white
        case .inRange, .normal:
            return AppColor.label
        }
    }

    private var outlineColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.72) : AppColor.graphite
    }

    @ViewBuilder private var background: some View {
        switch state {
        case .start:
            outlinedRangeSegment(
                UnevenRoundedRectangle(
                    topLeadingRadius: CornerRadius.small,
                    bottomLeadingRadius: CornerRadius.small,
                    bottomTrailingRadius: isSingleSelection ? CornerRadius.small : 0,
                    topTrailingRadius: isSingleSelection ? CornerRadius.small : 0,
                    style: .continuous
                ),
                showsLeadingCap: true,
                showsTrailingCap: isSingleSelection
            )
        case .end:
            outlinedRangeSegment(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: CornerRadius.small,
                    topTrailingRadius: CornerRadius.small,
                    style: .continuous
                ),
                showsLeadingCap: false,
                showsTrailingCap: true
            )
        case .inRange:
            outlinedRangeSegment(
                Rectangle(),
                showsLeadingCap: false,
                showsTrailingCap: false
            )
        case .normal:
            Color.clear
        }
    }

    private func outlinedRangeSegment<S: InsettableShape>(
        _ shape: S,
        showsLeadingCap: Bool,
        showsTrailingCap: Bool
    ) -> some View {
        shape
            .strokeBorder(outlineColor, lineWidth: Self.selectionLineWidth)
            .mask {
                RangeSelectionOutlineMask(
                    showsLeadingCap: showsLeadingCap,
                    showsTrailingCap: showsTrailingCap,
                    lineWidth: Self.selectionLineWidth,
                    cornerRadius: CornerRadius.small
                )
            }
    }
}

private struct RangeSelectionOutlineMask: View {
    let showsLeadingCap: Bool
    let showsTrailingCap: Bool
    let lineWidth: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let capWidth = min(proxy.size.width, cornerRadius + lineWidth)

            ZStack {
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(height: lineWidth)
                    Spacer(minLength: 0)
                    Rectangle()
                        .frame(height: lineWidth)
                }

                if showsLeadingCap {
                    Rectangle()
                        .frame(width: capWidth)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if showsTrailingCap {
                    Rectangle()
                        .frame(width: capWidth)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .foregroundStyle(.white)
        .compositingGroup()
    }
}
