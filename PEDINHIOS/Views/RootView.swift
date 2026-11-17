import SwiftUI

struct RootView: View {
    @State private var selection = 0

    var body: some View {
        ZStack {
            IceBackground()
            VStack(spacing: 0) {
                HeaderView()
                Group {
                    switch selection {
                    case 0: HomeView()
                    case 1: MenuView()
                    case 2: OffsetLabView()
                    default: SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                BottomBar(selection: $selection)
            }
        }
        .tint(Color.iceBlue)
    }
}

struct IceBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.012, green: 0.025, blue: 0.04)
            RadialGradient(colors: [Color.iceBlue.opacity(0.14), .clear],
                           center: .topTrailing, startRadius: 5, endRadius: 420)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Circle().fill(Color.iceBlue.opacity(0.05)).frame(width: 230, height: 230).blur(radius: 35)
                }
            }
        }.ignoresSafeArea()
    }
}

extension Color {
    static let iceBlue = Color(red: 0.45, green: 0.85, blue: 1.0)
    static let panel = Color(red: 0.035, green: 0.075, blue: 0.105)
}

struct HeaderView: View {
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 13).fill(Color.iceBlue.opacity(0.13))
                    .frame(width: 44, height: 44)
                Image(systemName: "snowflake").font(.system(size: 22, weight: .bold)).foregroundStyle(Color.iceBlue)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(AppConfig.name).font(.system(size: 16, weight: .black, design: .rounded))
                    .tracking(1.1).foregroundStyle(.white)
                Text("CONTROL CENTER  •  iOS").font(.system(size: 9, weight: .semibold)).tracking(1.4)
                    .foregroundStyle(Color.iceBlue.opacity(0.8))
            }
            Spacer()
            Circle().fill(Color.green).frame(width: 7, height: 7)
            Text("READY").font(.system(size: 10, weight: .bold)).foregroundStyle(.green)
        }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 16)
    }
}

struct BottomBar: View {
    @Binding var selection: Int
    private let items = [("house.fill", "Home"), ("slider.horizontal.3", "Menu"),
                         ("number", "Offset Lab"), ("gearshape.fill", "Settings")]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                Button { selection = index } label: {
                    VStack(spacing: 5) {
                        Image(systemName: items[index].0).font(.system(size: 17, weight: .semibold))
                        Text(items[index].1).font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(selection == index ? Color.iceBlue : Color.white.opacity(0.48))
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(selection == index ? Color.iceBlue.opacity(0.09) : .clear)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Rectangle().fill(Color.iceBlue.opacity(0.18)).frame(height: 1) }
    }
}

struct Panel<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label(title, systemImage: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(Color.iceBlue)
            content
        }
        .padding(16)
        .background(Color.panel.opacity(0.92))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.iceBlue.opacity(0.16), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
