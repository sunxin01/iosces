import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var store: MomentStore

    var body: some View {
        NavigationStack {
            ZStack {
                Accent.bg.ignoresSafeArea()

                if store.moments.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(store.moments) { moment in
                                NavigationLink(destination: MomentDetailView(moment: moment)) {
                                    MomentCardView(moment: moment)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 120)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("拾光")
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(Accent.secondary)
            Text("还没有记录")
                .font(.title2).bold()
                .foregroundColor(Accent.text)
            Text("点右下角 + 号,记下第一个重要时刻")
                .font(.subheadline)
                .foregroundColor(Accent.subtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

struct MomentCardView: View {
    let moment: Moment

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let firstName = moment.imageFilenames.first,
               let img = ImageStore.load(firstName) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(moment.title)
                            .font(.headline)
                            .foregroundColor(Accent.text)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Text(DateHelpers.dayFormatter.string(from: moment.date))
                            Text("·")
                            Text(DateHelpers.relativeLabel(for: moment.date))
                            if !moment.location.isEmpty {
                                Text("·")
                                Label(moment.location, systemImage: "mappin")
                                    .lineLimit(1)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(Accent.subtext)
                    }
                    Spacer()
                    Text(moment.mood.emoji)
                        .font(.system(size: 28))
                }

                if !moment.note.isEmpty {
                    Text(moment.note)
                        .font(.subheadline)
                        .foregroundColor(Accent.text.opacity(0.85))
                        .lineLimit(3)
                }
            }
            .padding(14)
        }
        .background(Accent.card)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        let store = MomentStore()
        store.add(Moment(title: "示例时刻", note: "这是一段示例笔记",
                         date: Date(), mood: .happy, location: "上海"))
        return TimelineView().environmentObject(store)
    }
}
