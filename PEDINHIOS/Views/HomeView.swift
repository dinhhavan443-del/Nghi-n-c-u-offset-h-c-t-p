import SwiftUI

struct HomeView: View {
    @Binding var selection: Int
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("WELCOME TO THE LAB").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(.iceBlue)
                    Text("PEDINHIOS\nEDUCATION LAB").font(.system(size: 29, weight: .black, design: .rounded)).foregroundColor(.white)
                    Text("Học phân tích tệp, kiến trúc ARM64, HEX, Mach-O và cách tính offset bằng dữ liệu bạn có quyền nghiên cứu.")
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.65))
                    HStack { Label("LOCAL STUDY MODE", systemImage: "checkmark.shield.fill").font(.system(size: 10, weight: .bold)).foregroundColor(.green); Spacer(); Text("v2.0 LAB").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.white.opacity(0.5)) }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
                    .background(LinearGradient(colors: [Color.iceBlue.opacity(0.17), Color.panel], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.iceBlue.opacity(0.25), lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 22))
                Panel(title: "LAB MODULES", icon: "square.grid.2x2.fill") {
                    HomeModule(icon: "number", title: "Offset Calculator", detail: "Base + Offset • RVA/VA • Hex/Decimal") { selection = 1 }
                    HomeModule(icon: "doc.viewfinder", title: "File & Binary Lab", detail: "Chọn tệp • Hex dump • ASCII strings • Header") { selection = 2 }
                    HomeModule(icon: "cpu", title: "ARM64 Learning", detail: "Register • Instruction • Addressing") { selection = 3 }
                    HomeModule(icon: "book.closed", title: "Study Library", detail: "ASLR • Mach-O • IPA • Dylib • Pointer") { selection = 3 }
                }
                Panel(title: "QUICK FACTS", icon: "info.circle") {
                    InfoLine(label: "Admin", value: AppConfig.admin)
                    InfoLine(label: "TikTok", value: "Pedinhios")
                    InfoLine(label: "iOS target", value: "15.0+")
                    InfoLine(label: "File processing", value: "On-device")
                }
                Text("Chỉ phân tích tệp người dùng chọn hoặc dữ liệu mẫu; không đọc/ghi bộ nhớ tiến trình ứng dụng khác.")
                    .font(.system(size: 10)).foregroundColor(.white.opacity(0.42)).frame(maxWidth: .infinity, alignment: .leading)
            }.padding(16)
        }
    }
}

struct HomeModule: View {
    let icon: String; let title: String; let detail: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: icon).foregroundColor(.iceBlue).frame(width: 36, height: 36).background(Color.iceBlue.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) { Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(.white); Text(detail).font(.system(size: 10)).foregroundColor(.white.opacity(0.5)) }
                Spacer(); Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.35))
            }
        }.buttonStyle(.plain)
    }
}

struct InfoLine: View {
    let label: String; let value: String
    var body: some View { HStack { Text(label).foregroundColor(.white.opacity(0.5)); Spacer(); Text(value).foregroundColor(.white).font(.system(size: 12, weight: .semibold)) }.font(.system(size: 12)) }
}
