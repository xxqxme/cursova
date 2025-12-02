import SwiftUI

struct DetailView: View {
    let artwork: Artwork
    @ObservedObject var vm: ArtViewModel
    
    // Стан для сповіщення про збереження фото
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Картинка
                if let urlString = artwork.primaryImage, let url = URL(string: urlString), !urlString.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fit)
                        case .failure:
                            Color.gray.frame(height: 300)
                        case .empty:
                            ProgressView().frame(height: 300).frame(maxWidth: .infinity)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Color.gray.frame(height: 300).overlay(Text("Зображення відсутнє"))
                }

                // Кнопки дій (Улюблене + Зберегти фото)
                HStack {
                    // Кнопка "Улюблене"
                    Button(action: {
                        vm.toggleFavorite(artwork)
                    }) {
                        HStack {
                            Image(systemName: vm.isFavorite(artwork) ? "star.fill" : "star")
                            Text(vm.isFavorite(artwork) ? "У колекції" : "Додати в колекцію")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(vm.isFavorite(artwork) ? .orange : .blue)

                    Spacer()

                    // Кнопка "Зберегти фото"
                    if artwork.primaryImage != nil {
                        Button(action: {
                            saveImageToGallery()
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2)
                        }
                    }
                }
                .padding(.horizontal)

                // Текстова інформація
                VStack(alignment: .leading, spacing: 10) {
                    Text(artwork.title ?? "Без назви")
                        .font(.title)
                        .bold()

                    Group {
                        Text("Автор: ").bold() + Text(artwork.artistDisplayName ?? "Невідомий")
                        if let date = artwork.objectDate {
                            Text("Дата: ").bold() + Text(date)
                        }
                        if let medium = artwork.medium {
                            Text("Матеріал: ").bold() + Text(medium)
                        }
                    }
                    .font(.body)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Деталі")
        .navigationBarTitleDisplayMode(.inline)
        .alert(saveMessage, isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    // Функція збереження в галерею
    func saveImageToGallery() {
        guard let urlString = artwork.primaryImage, let url = URL(string: urlString) else { return }
        
        // Завантажуємо фото у фоні і зберігаємо
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    // Збереження в фотоальбом
                    UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                    saveMessage = "Фото збережено в галерею!"
                    showingSaveAlert = true
                }
            } catch {
                saveMessage = "Помилка збереження."
                showingSaveAlert = true
            }
        }
    }
}
