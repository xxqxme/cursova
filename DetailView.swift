import SwiftUI
import Photos

struct DetailView: View {
    let artwork: Artwork
    @ObservedObject var vm: ArtViewModel
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSettingsAction = false
    
    @State private var isAnimatingHeart = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Блок відображення картинки
                if let urlString = artwork.primaryImage, let url = URL(string: urlString), !urlString.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                                .shadow(radius: 8)
                        case .empty:
                            ProgressView().frame(height: 300)
                        case .failure:
                            Color.gray.opacity(0.2).frame(height: 300)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 15) {
                    HStack(alignment: .top) {
                        Text(artwork.title ?? "Без назви")
                            .font(.title2)
                            .bold()
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                vm.toggleFavorite(artwork)
                                isAnimatingHeart = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isAnimatingHeart = false
                            }
                        }) {
                            Image(systemName: vm.isFavorite(artwork) ? "heart.fill" : "heart")
                                .font(.title)
                                .foregroundColor(vm.isFavorite(artwork) ? .red : .gray)
                                .scaleEffect(isAnimatingHeart ? 1.4 : 1.0)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        detailRow(icon: "paintbrush.fill", text: artwork.artistDisplayName ?? "Невідомий")
                        if let date = artwork.objectDate {
                            detailRow(icon: "calendar", text: date)
                        }
                        if let medium = artwork.medium {
                            detailRow(icon: "drop.fill", text: medium)
                        }
                    }
                    
                    Divider()
                    
                    if artwork.primaryImage != nil {
                        Button(action: { checkPermissionAndSave() }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Зберегти в галерею")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 5, y: -2)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showingAlert) {
            if isSettingsAction {
                Button("Налаштування") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Скасувати", role: .cancel) { }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    func detailRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.indigo)
            Text(text)
                .foregroundColor(.secondary)
        }
    }

    func checkPermissionAndSave() {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            saveImageToGallery()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    saveImageToGallery()
                }
            }
        case .denied, .restricted:
            alertTitle = "Доступ обмежено"
            alertMessage = "Ви заборонили доступ до фото. Щоб зберегти картину, змініть це у налаштуваннях."
            isSettingsAction = true
            showingAlert = true
        @unknown default:
            break
        }
    }
    
    func saveImageToGallery() {
        guard let urlString = artwork.primaryImage, let url = URL(string: urlString) else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    try await PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
                    }
                    alertTitle = "Успішно"
                    alertMessage = "Картину збережено у ваші фото."
                    isSettingsAction = false
                    showingAlert = true
                }
            } catch {
                alertTitle = "Помилка"
                alertMessage = "Не вдалося зберегти зображення."
                isSettingsAction = false
                showingAlert = true
            }
        }
    }
}
