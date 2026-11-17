import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel(title: "ABOUT", icon: "snowflake") {
                    InfoLine(label: "Application", value: AppConfig.name)
                    InfoLine(label: "Version", value: "1.0.0")
                    InfoLine(label: "Minimum iOS", value: "15.0")
                    InfoLine(label: "Architecture", value: "Universal iOS target")
                }
                Panel(title: "CREDITS", icon: "person.crop.circle") {
                    InfoLine(label: "Admin", value: "Anh Định")
                    InfoLine(label: "TikTok", value: "Pedinhios")
                }
                Text("PEDINHIOS MENU là bộ công cụ học tập và kiểm thử. Không inject, không đọc/ghi bộ nhớ tiến trình bên thứ ba.")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.padding(18)
        }
    }
}
