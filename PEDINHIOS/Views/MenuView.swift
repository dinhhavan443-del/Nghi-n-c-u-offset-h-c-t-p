import SwiftUI

struct MenuView: View {
    @State private var haptics = true
    @State private var particles = true
    @State private var compact = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Panel(title: "QUICK CONTROLS", icon: "slider.horizontal.3") {
                    ToggleRow(title: "Haptic feedback", detail: "Rung nhẹ khi thao tác", isOn: $haptics)
                    ToggleRow(title: "Background particles", detail: "Hiệu ứng nền trong ứng dụng", isOn: $particles)
                    ToggleRow(title: "Compact interface", detail: "Thu gọn thẻ điều khiển", isOn: $compact)
                }
                Panel(title: "AVAILABLE MODULES", icon: "square.stack.3d.up") {
                    ModuleRow(icon: "number", title: "Offset Calculator", subtitle: "Tính toán địa chỉ ví dụ")
                    ModuleRow(icon: "cpu", title: "ARM64 Learning", subtitle: "Kiến thức kiến trúc CPU")
                    ModuleRow(icon: "doc.zipper", title: "IPA File Inspector", subtitle: "Đọc thông tin tệp do bạn chọn")
                    ModuleRow(icon: "shippingbox", title: "Dylib Inspector", subtitle: "Tìm hiểu thư viện đóng gói")
                }
                Text("Các công tắc chỉ điều khiển chức năng bên trong PEDINHIOS MENU.")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.45)).frame(maxWidth: .infinity, alignment: .leading)
            }.padding(18)
        }
    }
}

struct ToggleRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                Text(detail).font(.system(size: 10)).foregroundStyle(.white.opacity(0.48))
            }
            Spacer()
            Toggle(title, isOn: $isOn).labelsHidden().tint(Color.iceBlue)
        }
    }
}

struct ModuleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Color.iceBlue).frame(width: 34, height: 34)
                .background(Color.iceBlue.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                Text(subtitle).font(.system(size: 10)).foregroundStyle(.white.opacity(0.48))
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.3))
        }
    }
}
