import SwiftUI

struct MomentDetailView: View {
    @EnvironmentObject private var store: MomentStore
    @Environment(\.dismiss) private var dismiss

    let moment: Moment
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !moment.imageFilenames.isEmpty {
                    TabView {
                        ForEach(moment.imageFilenames, id: \.self) { name in
                            if let img = ImageStore.load(name) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                    }
                    .frame(height: 320)
                    .tabViewStyle(.page)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Text(moment.title)
                            .font(.title2).bold()
                            .foregroundColor(Accent.text)
                        Spacer()
                        VStack {
                            Text(moment.mood.emoji)
                                .font(.system(size: 36))
                            Text(moment.mood.displayName)
                                .font(.caption)
                                .foregroundColor(Accent.subtext)
                        }
                    }

                    HStack(spacing: 8) {
                        Label(DateHelpers.dayFormatter.string(from: moment.date),
                              systemImage: "calendar")
                        Text(DateHelpers.weekdayFormatter.string(from: moment.date))
                        Text("·")
                        Text(DateHelpers.relativeLabel(for: moment.date))
                    }
                    .font(.subheadline)
                    .foregroundColor(Accent.subtext)

                    if !moment.location.isEmpty {
                        Label(moment.location, systemImage: "mappin")
                            .font(.subheadline)
                            .foregroundColor(Accent.subtext)
                    }

                    if !moment.note.isEmpty {
                        Divider()
                        Text(moment.note)
                            .font(.body)
                            .foregroundColor(Accent.text)
                            .lineSpacing(6)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 12)
        }
        .background(Accent.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("删除这一刻?", isPresented: $showDeleteAlert) {
            Button("删除", role: .destructive) {
                store.delete(moment)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("照片和文字都会被删除,无法恢复。")
        }
    }
}
