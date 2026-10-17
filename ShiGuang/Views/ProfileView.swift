import SwiftUI
import UniformTypeIdentifiers

struct ProfileView: View {
    @EnvironmentObject private var store: MomentStore
    @State private var showingClearAlert = false
    @State private var exportDoc: JSONDocument?
    @State private var showingExport = false

    var body: some View {
        NavigationStack {
            ZStack {
                Accent.bg.ignoresSafeArea()
                List {
                    Section {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(
                                        colors: [Accent.primary, Accent.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing))
                                    .frame(width: 60, height: 60)
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 26))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("拾光")
                                    .font(.title3).bold()
                                    .foregroundColor(Accent.text)
                                Text("把每个重要时刻,都收进时光")
                                    .font(.caption)
                                    .foregroundColor(Accent.subtext)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Accent.card)

                    Section("数据") {
                        Button {
                                exportData()
                        } label: {
                            Label("导出全部数据 (JSON)", systemImage: "square.and.arrow.up")
                                .foregroundColor(Accent.text)
                        }

                        Button(role: .destructive) {
                            showingClearAlert = true
                        } label: {
                            Label("清除全部数据", systemImage: "trash")
                        }
                    }
                    .listRowBackground(Accent.card)

                    Section("关于") {
                        HStack {
                            Text("版本")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(Accent.subtext)
                        }
                        HStack {
                            Text("记录数")
                            Spacer()
                            Text("\(store.moments.count)")
                                .foregroundColor(Accent.subtext)
                        }
                    }
                    .listRowBackground(Accent.card)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("我的")
            .alert("清除全部数据?", isPresented: $showingClearAlert) {
                Button("清除", role: .destructive) {
                    store.deleteAll()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("所有时刻、照片、心情都会被删除,无法恢复。")
            }
            .fileExporter(
                isPresented: $showingExport,
                document: exportDoc,
                contentType: .json,
                defaultFilename: "shiguang-export.json"
            ) { _ in }
        }
    }

    private func exportData() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(store.moments) {
            exportDoc = JSONDocument(data: data)
            showingExport = true
        }
    }
}

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
