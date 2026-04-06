import WidgetKit
import SwiftUI

@main
struct AttendanceWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.2, *) {
            AttendanceActivityWidget()
        }
    }
}
