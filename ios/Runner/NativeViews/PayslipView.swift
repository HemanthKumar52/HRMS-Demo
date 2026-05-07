import SwiftUI

// MARK: - Payslip View

struct PayslipView: View {
    @ObservedObject var viewModel: PayslipViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Month/Year selector
                monthSelector
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .fadeInOnAppear(delay: 0)

                // Summary card
                summaryCard
                    .padding(.horizontal, 20)
                    .fadeInOnAppear(delay: 0.05)

                // Earnings donut
                earningsSection
                    .padding(.horizontal, 20)
                    .fadeInOnAppear(delay: 0.1)

                // Deductions donut
                deductionsSection
                    .padding(.horizontal, 20)
                    .fadeInOnAppear(delay: 0.15)

                // Action buttons
                actionButtons
                    .padding(.horizontal, 20)
                    .fadeInOnAppear(delay: 0.2)

                Spacer(minLength: 100)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Button {
                viewModel.previousMonth()
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "3B5FE5"))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.month)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("\(viewModel.year)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                viewModel.nextMonth()
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "3B5FE5"))
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 16) {
            if !viewModel.employeeName.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.employeeName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text(viewModel.designation)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Text(viewModel.payDate)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            HStack {
                _PaySummaryItem(label: "Gross", value: formatCurrency(viewModel.grossSalary))
                _PaySummaryItem(label: "Deductions", value: formatCurrency(viewModel.totalDeductions))
                _PaySummaryItem(label: "Net Pay", value: formatCurrency(viewModel.netPay))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "10B981"), Color(hex: "34D399")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(hex: "10B981").opacity(0.3), radius: 16, y: 6)
    }

    // MARK: - Earnings Section

    private var earningsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Earnings")
                .font(.system(size: 16, weight: .bold))

            HStack(spacing: 20) {
                // Donut chart
                _DonutChart(items: viewModel.earnings.map { ($0.color, $0.amount) }, centerText: formatCurrency(viewModel.totalEarnings))
                    .frame(width: 120, height: 120)

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.earnings) { item in
                        HStack(spacing: 6) {
                            Circle().fill(item.color).frame(width: 8, height: 8)
                            Text(item.label)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(item.amount))
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Deductions Section

    private var deductionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Deductions")
                .font(.system(size: 16, weight: .bold))

            HStack(spacing: 20) {
                // Donut chart
                _DonutChart(items: viewModel.deductions.map { ($0.color, $0.amount) }, centerText: formatCurrency(viewModel.totalDeductions))
                    .frame(width: 120, height: 120)

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.deductions) { item in
                        HStack(spacing: 6) {
                            Circle().fill(item.color).frame(width: 8, height: 8)
                            Text(item.label)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(item.amount))
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.viewPayslip()
            } label: {
                HStack {
                    Image(systemName: "eye.fill")
                    Text("View")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "3B5FE5"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                viewModel.downloadPayslip()
            } label: {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Download")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "3B5FE5"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "3B5FE5").opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "\u{20B9}"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\u{20B9}0"
    }
}

// MARK: - Sub-components

private struct _PaySummaryItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct _DonutChart: View {
    let items: [(Color, Double)]
    let centerText: String

    var body: some View {
        ZStack {
            let total = items.reduce(0) { $0 + $1.1 }
            if total > 0 {
                ForEach(0..<items.count, id: \.self) { index in
                    let startAngle = angleFor(index: index, total: total)
                    let endAngle = angleFor(index: index + 1, total: total)
                    _DonutSegment(startAngle: startAngle, endAngle: endAngle, color: items[index].0)
                }
            } else {
                Circle()
                    .stroke(Color(UIColor.systemGray4), lineWidth: 16)
            }

            Text(centerText)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
        }
    }

    private func angleFor(index: Int, total: Double) -> Angle {
        let sum = items.prefix(index).reduce(0) { $0 + $1.1 }
        return .degrees(sum / total * 360 - 90)
    }
}

private struct _DonutSegment: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2
            Path { path in
                path.addArc(center: center, radius: radius - 8, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            }
            .stroke(color, style: StrokeStyle(lineWidth: 16, lineCap: .butt))
        }
    }
}
