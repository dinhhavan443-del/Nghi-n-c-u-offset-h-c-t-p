import SwiftUI

struct RootView: View {
    @State private var selection = 0
    @State private var showQuickMenu = false
    @State private var dragOffset = CGSize.zero

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            IceBackground()
            VStack(spacing: 0) {
                HeaderView()
                Group {
                    switch selection {
                    case 0: HomeView(selection: $selection)
                    case 1: OffsetLabView()
                    case 2: FileLabView()
                    case 3: LearningView()
                    default: SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                BottomBar(selection: $selection)
            }
            VStack(alignment: .trailing, spacing: 10) {
                if showQuickMenu {
                    quickAction("Offset Lab", icon: "number", tab: 1)
                    quickAction("File Lab", icon: "doc.text.magnifyingglass", tab: 2)
                    quickAction("Learning", icon: "book", tab: 3)
                }
                Button { withAnimation(.spring()) { showQuickMenu.toggle() } } label: {
                    Image(systemName: showQuickMenu ? "xmark" : "sparkles")
                        .font(.system(size: 19, weight: .bold)).foregroundColor(.black)
                        .frame(width: 54, height: 54).background(Color.iceBlue)
                        .clipShape(Circle()).shadow(color: Color.iceBlue.opacity(0.35), radius: 12)
                }.buttonStyle(.plain)
            }
            .padding(.trailing, 17).padding(.bottom, 76)
            .offset(dragOffset)
            .gesture(DragGesture().onChanged { dragOffset = $0.translation }.onEnded { _ in })
        }
        .tint(Color.iceBlue)
    }

    private func quickAction(_ title: String, icon: String, tab: Int) -> some View {
        Button { selection = tab; showQuickMenu = false } label: {
            Label(title, systemImage: icon).font(.system(size: 12, weight: .bold))
                .foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 11)
                .background(Color.panel).overlay(Capsule().stroke(Color.iceBlue.opacity(0.35), lineWidth: 1)).clipShape(Capsule())
        }.buttonStyle(.plain)
    }
}

struct IceBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.012, green: 0.025, blue: 0.04)
            RadialGradient(colors: [Color.iceBlue.opacity(0.14), .clear], center: .topTrailing, startRadius: 5, endRadius: 420)
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
            Image(systemName: "snowflake").font(.system(size: 22, weight: .bold)).foregroundColor(.iceBlue)
                .frame(width: 44, height: 44).background(Color.iceBlue.opacity(0.13)).clipShape(RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text(AppConfig.name).font(.system(size: 16, weight: .black, design: .rounded)).tracking(1.1).foregroundColor(.white)
                Text("EDUCATION & RESEARCH LAB").font(.system(size: 9, weight: .semibold)).tracking(1.2).foregroundColor(.iceBlue.opacity(0.8))
            }
            Spacer()
            Circle().fill(Color.green).frame(width: 7, height: 7)
            Text("READY").font(.system(size: 10, weight: .bold)).foregroundColor(.green)
        }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 14)
    }
}

struct BottomBar: View {
    @Binding var selection: Int
    private let items = [("house.fill", "Home"), ("number", "Offset"), ("doc.text", "Files"), ("book.closed", "Learn"), ("gearshape.fill", "More")]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                Button { selection = index } label: {
                    VStack(spacing: 5) {
                        Image(systemName: items[index].0).font(.system(size: 16, weight: .semibold))
                        Text(items[index].1).font(.system(size: 9, weight: .semibold))
                    }.foregroundColor(selection == index ? .iceBlue : .white.opacity(0.48))
                        .frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(selection == index ? Color.iceBlue.opacity(0.09) : .clear)
                }.buttonStyle(.plain)
            }
        }.padding(.horizontal, 5).background(.ultraThinMaterial)
            .overlay(alignment: .top) { Rectangle().fill(Color.iceBlue.opacity(0.18)).frame(height: 1) }
    }
}

struct Panel<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    init(title: String, icon: String, @ViewBuilder content: () -> Content) { self.title = title; self.icon = icon; self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label(title, systemImage: icon).font(.system(size: 13, weight: .bold)).foregroundColor(.iceBlue)
            content
        }.padding(16).background(Color.panel.opacity(0.94))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.iceBlue.opacity(0.16), lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
