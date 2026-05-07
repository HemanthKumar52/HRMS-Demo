import SwiftUI
import Flutter

class ProfileSheetViewModel: ObservableObject {
    let channel: FlutterMethodChannel?

    @Published var fullName: String = ""
    @Published var initials: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var dob: String = ""
    @Published var department: String = ""
    @Published var designation: String = ""
    @Published var badgeId: String = ""
    @Published var joiningDate: String = ""
    @Published var managerName: String = ""
    @Published var role: String = ""

    init(channel: FlutterMethodChannel?, args: [String: Any]?) {
        self.channel = channel
        if let args = args { update(from: args) }
    }

    func update(from data: [String: Any]) {
        if let n = data["fullName"] as? String {
            fullName = n
            let parts = n.split(separator: " ")
            initials = parts.prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
        }
        if let e = data["email"] as? String { email = e }
        if let p = data["phone"] as? String { phone = p }
        if let d = data["dob"] as? String { dob = d }
        if let d = data["department"] as? String { department = d }
        if let d = data["designation"] as? String { designation = d }
        if let b = data["badgeId"] as? String { badgeId = b }
        if let j = data["joiningDate"] as? String { joiningDate = j }
        if let m = data["managerName"] as? String { managerName = m }
        if let r = data["role"] as? String { role = r }
    }
}
