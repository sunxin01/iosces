import SwiftUI
import PhotosUI

struct AddMomentView: View {
    @EnvironmentObject private var store: MomentStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var mood: Mood = .happy
    @State private var location: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("标题") {
                    TextField("这一刻想叫什么?", text: $title)
                }

                Section("内容") {
                    TextEditor(text: $note)
                        .frame(minHeight: 110)
                }

                Section("照片") {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 9,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text(selectedImages.isEmpty ? "选择照片(最多 9 张)" : "已选 \(selectedImages.count) 张,点这里重选")
                        }
                    }
                    .onChange(of: selectedItems) { newItems in
                        loadImages(from: newItems)
                    }

                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { _, img in
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 78, height: 78)
                                        .clipped()
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("日期") {
                    DatePicker("发生时间", selection: $date, displayedComponents: .date)
                }

                Section("心情") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Mood.allCases) { m in
                                Button {
                                    mood = m
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(m.emoji)
                                            .font(.system(size: 30))
                                        Text(m.displayName)
                                            .font(.caption2)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 10)
                                    .background(mood == m ? Accent.secondary.opacity(0.4) : Color.clear)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(mood == m ? Accent.primary : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("地点(可选)") {
                    TextField("在哪里?", text: $location)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Accent.bg)
            .navigationTitle("记录时刻")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveMoment() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) {
        selectedImages = []
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                if case .success(let data?) = result, let img = UIImage(data: data) {
                    DispatchQueue.main.async {
                        selectedImages.append(img)
                    }
                }
            }
        }
    }

    private func saveMoment() {
        var filenames: [String] = []
        for img in selectedImages {
            if let name = ImageStore.save(img) {
                filenames.append(name)
            }
        }
        let m = Moment(
            title: title.trimmingCharacters(in: .whitespaces),
            note: note,
            date: date,
            mood: mood,
            location: location.trimmingCharacters(in: .whitespaces),
            imageFilenames: filenames
        )
        store.add(m)
        dismiss()
    }
}
