import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: MomentStore
    @State private var selectedTab = 0
    @State private var showingAdd = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                TimelineView()
                    .tabItem {
                        Label("时光轴", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(0)

                StatsView()
                    .tabItem {
                        Label("统计", systemImage: "chart.bar")
                    }
                    .tag(1)

                ProfileView()
                    .tabItem {
                        Label("我的", systemImage: "person.crop.circle")
                    }
                    .tag(2)
            }
            .accentColor(Accent.primary)

            Button {
                showingAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Accent.primary)
                    .clipShape(Circle())
                    .shadow(color: Accent.primary.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 76)
        }
        .sheet(isPresented: $showingAdd) {
            AddMomentView()
                .environmentObject(store)
        }
    }
}
