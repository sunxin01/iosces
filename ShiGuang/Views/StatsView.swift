import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: MomentStore

    private var totalMoments: Int { store.moments.count }

    private var thisMonthCount: Int {
        let cal = Calendar.current
        let now = Date()
        return store.moments.filter {
            cal.isDate($0.date, equalTo: now, toGranularity: .month)
        }.count
    }

    private var totalImages: Int {
        store.moments.reduce(0) { $0 + $1.imageFilenames.count }
    }

    private var moodCounts: [(Mood, Int)] {
        var dict: [Mood: Int] = [:]
        for m in store.moments { dict[m.mood, default: 0] += 1 }
        return Mood.allCases.map { ($0, dict[$0] ?? 0) }
    }

    private var longestStreak: Int {
        let cal = Calendar.current
        let days = Set(store.moments.map { cal.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted()
        var best = 1, cur = 1
        for i in 1..<sorted.count {
            if let prev = cal.date(byAdding: .day, value: 1, to: sorted[i-1]),
               cal.isDate(prev, inSameDayAs: sorted[i]) {
                cur += 1
                best = max(best, cur)
            } else if !cal.isDate(sorted[i-1], inSameDayAs: sorted[i]) {
                cur = 1
            }
        }
        return best
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Accent.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            StatCard(title: "总记录", value: "\(totalMoments)", icon: "square.stack.3d.up")
                            StatCard(title: "本月新增", value: "\(thisMonthCount)", icon: "calendar.badge.plus")
                        }
                        HStack(spacing: 12) {
                            StatCard(title: "照片数", value: "\(totalImages)", icon: "photo")
                            StatCard(title: "连续记录", value: "\(longestStreak) 天", icon: "flame")
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("心情分布")
                                .font(.headline)
                                .foregroundColor(Accent.text)
                            ForEach(moodCounts, id: \.0.id) { mood, count in
                                HStack {
                                    Text(mood.emoji)
                                    Text(mood.displayName)
                                        .foregroundColor(Accent.text)
                                    Spacer()
                                    GeometryReader { geo in
                                        let maxCount = max(moodCounts.map { $0.1 }.max() ?? 1, 1)
                                        let ratio = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Accent.primary.opacity(0.7))
                                            .frame(width: geo.size.width * ratio, height: 10)
                                    }
                                    .frame(height: 10)
                                    .frame(maxWidth: 140)
                                    Text("\(count)")
                                        .font(.caption)
                                        .foregroundColor(Accent.subtext)
                                        .frame(width: 28, alignment: .trailing)
                                }
                            }
                        }
                        .padding(16)
                        .background(Accent.card)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                    }
                    .padding(16)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("统计")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Accent.primary)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Accent.text)
            Text(title)
                .font(.caption)
                .foregroundColor(Accent.subtext)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Accent.card)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
