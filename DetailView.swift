import SwiftUI

struct DetailView: View {
    let artwork: Artwork
    @ObservedObject var vm: ArtViewModel
    
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""
    
    @State private var isAnimatingHeart = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                if let urlString = artwork.primaryImage, let url = URL(string: urlString), !urlString.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                                .shadow(radius: 8)
                                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
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
                        Button(action: { saveImageToGallery() }) {
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
        .alert(saveMessage, isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
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
    
    func saveImageToGallery() {
        guard let urlString = artwork.primaryImage, let url = URL(string: urlString) else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                    saveMessage = "Успішно збережено!"
                    showingSaveAlert = true
                }
            } catch {
                saveMessage = "Помилка збереження"
                showingSaveAlert = true
            }
        }
    }
}
