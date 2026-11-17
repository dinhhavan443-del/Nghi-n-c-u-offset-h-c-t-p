import SwiftUI

struct SettingsView: View {
    @State private var haptics = true
    @State private var showDisclaimer = true
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                Panel(title: "APP SETTINGS", icon: "gearshape") {
                    ToggleRow(title: "Haptic feedback", detail: "Phản hồi rung khi hệ thống hỗ trợ", isOn: $haptics)
                    ToggleRow(title: "Show learning notices", detail: "Hiển thị chú thích trong phòng lab", isOn: $showDisclaimer)
                }
                Panel(title: "ABOUT PEDINHIOS", icon: "snowflake") {
                    InfoLine(label: "Application", value: AppConfig.name)
                    InfoLine(label: "Version", value: "2.0 Education Lab")
                    InfoLine(label: "Minimum iOS", value: "15.0")
                    InfoLine(label: "Architecture", value: "iPhone + iPad")
                    InfoLine(label: "Admin", value: "Anh Định")
                    InfoLine(label: "TikTok", value: "Pedinhios")
                }
                Panel(title: "PRIVACY & SAFETY", icon: "lock.shield") {
                    Text("Tệp được chọn được xử lý cục bộ trong ứng dụng. PEDINHIOS MENU không inject mã, không sửa tệp gốc, không đọc/ghi bộ nhớ tiến trình của game hoặc ứng dụng khác và không cung cấp quyền vượt sandbox iOS.")
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.62))
                }
            }.padding(16)
        }
    }
}
