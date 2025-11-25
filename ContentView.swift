import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ArtViewModel()
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Пошук: назва, художник, тема...", text: $vm.query)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await vm.search() }
                        }
                        .focused($isTextFieldFocused)

                    Button(action: {
                        Task { await vm.search() }
                        isTextFieldFocused = false
                    }) {
                        Image(systemName: "magnifyingglass")
                            .padding(8)
                    }
                    .buttonStyle(.bordered)
                }
                .padding([.horizontal, .top])

                if vm.isLoading {
                    ProgressView("Завантаження...")
                        .padding()
                } else if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .padding()
                }

                List(vm.artworks) { art in
                    NavigationLink(value: art) {
                        HStack(spacing: 12) {
                            // Thumbnail
                            if let thumb = art.primaryImageSmall, let url = URL(string: thumb) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 80, height: 80)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                    case .failure:
                                        Color.gray.frame(width: 80, height: 80)
                                    @unknown default:
                                        Color.gray.frame(width: 80, height: 80)
                                    }
                                }
                                .cornerRadius(6)
                            } else {
                                Color.gray.frame(width: 80, height: 80)
                                    .cornerRadius(6)
                            }

                            // Title + author
                            VStack(alignment: .leading) {
                                Text(art.title ?? "Без назви")
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(art.artistDisplayName ?? "Невідомий автор")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Каталог мистецтва")
            .navigationDestination(for: Artwork.self) { art in
                DetailView(artwork: art)
            }
        }
    }
}
