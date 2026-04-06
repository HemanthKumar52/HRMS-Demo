import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes
struct AttendanceAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var workedHours: Int
        var workedMinutes: Int
        var progress: Double
        var status: String
    }

    var userName: String
    var punchInTime: Int // Unix timestamp
    var targetHours: Int
}

// MARK: - Live Activity Widget
@available(iOS 16.2, *)
struct AttendanceActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AttendanceAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("\(context.state.workedHours)h \(String(format: "%02d", context.state.workedMinutes))m")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        Text("of \(context.attributes.targetHours)h target")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 6) {
                        Text("Working")
                            .font(.headline)
                            .foregroundColor(.green)

                        ProgressView(value: context.state.progress)
                            .progressViewStyle(.linear)
                            .tint(.green)
                    }
                    .padding(.horizontal)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.secondary)
                        Text(context.attributes.userName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Since \(formattedTime(context.attributes.punchInTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                // Compact Leading
                Image(systemName: "clock.fill")
                    .foregroundColor(.green)
            } compactTrailing: {
                // Compact Trailing
                Text("\(context.state.workedHours):\(String(format: "%02d", context.state.workedMinutes))")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            } minimal: {
                // Minimal
                Image(systemName: "clock.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Lock Screen View
@available(iOS 16.2, *)
struct LockScreenView: View {
    let context: ActivityViewContext<AttendanceAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Left: Timer circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: context.state.progress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "clock.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }

            // Center: Info
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.userName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Punched in at \(formattedTime(context.attributes.punchInTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Right: Duration
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(context.state.workedHours)h \(String(format: "%02d", context.state.workedMinutes))m")
                    .font(.title3.bold())
                    .foregroundColor(.primary)

                Text("/ \(context.attributes.targetHours)h")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
    }
}

// MARK: - Helper
func formattedTime(_ timestamp: Int) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
}
