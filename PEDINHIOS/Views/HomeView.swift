import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("WELCOME BACK").font(.system(size: 10, weight: .bold)).tracking(2).foregroundStyle(Color.iceBlue)
                    Text("PEDINHIOS\nCONTROL").font(.system(size: 32, weight: .black, design: .rounded)).foregroundStyle(.white)
                    Text("Bộ công cụ nghiên cứu và tiện ích iOS").font(.system(size: 13)).foregroundStyle(.white.opacity(0.62))
                    HStack {
                        Label("ỨNG DỤNG ĐANG HOẠT ĐỘNG", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 10, weight: .bold)).foregroundStyle(.green)
                        Spacer()
                        Text("v1.0").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.5))
                    }.padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(LinearGradient(colors: [Color.iceBlue.opacity(0.17), Color.panel], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.iceBlue.opacity(0.25), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 22))

                Panel(title: "TOOLS OVERVIEW", icon: "square.grid.2x2.fill") {
                    HStack(spacing: 10) {
                        StatTile(value: "04", label: "MODULES")
                        StatTile(value: "ARM64", label: "ARCH LAB")
                        StatTile(value: "iOS 15+", label: "TARGET")
                    }
                }
                Panel(title: "PROJECT INFORMATION", icon: "info.circle") {
                    InfoLine(label: "Administrator", value: AppConfig.admin)
                    InfoLine(label: "Social", value: AppConfig.social)
                    InfoLine(label: "Build", value: "GitHub Actions")
                }
                Text("PEDINHIOS MENU • EDUCATIONAL TOOLKIT").font(.system(size: 9, weight: .semibold)).tracking(1.2)
                    .foregroundStyle(.white.opacity(0.3)).padding(.top, 4)
            }.padding(18)
        }
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.system(size: 15, weight: .black, design: .rounded)).foregroundStyle(.white)
            Text(label).font(.system(size: 8, weight: .bold)).foregroundStyle(Color.iceBlue.opacity(0.8))
        }.frame(maxWidth: .infinity).padding(.vertical, 13)
            .background(Color.white.opacity(0.045)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InfoLine: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value).foregroundStyle(.white).fontWeight(.semibold)
        }.font(.system(size: 12))
    }
}
