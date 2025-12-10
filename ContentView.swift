import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ArtViewModel()
    
    var body: some View {
        TabView {
            // Вкладка 1: Пошук
            SearchView(vm: vm)
                .tabItem {
                    Label("Пошук", systemImage: "magnifyingglass")
                }
            
            // Вкладка 2: Улюблене
            FavoritesView(vm: vm)
                .tabItem {
                    Label("Колекція", systemImage: "heart.fill")
                }
        }
        .accentColor(.indigo)
    }
}

// Екран пошуку
struct SearchView: View {
    @ObservedObject var vm: ArtViewModel
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Поле пошуку
                HStack {
                    TextField("Пошук...", text: $vm.query) // Текст змінив тут
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .focused($isFocused)
                        .submitLabel(.search)
                        .onSubmit { Task { await vm.search() } }
                    
                    Button {
                        Task { await vm.search() }
                        isFocused = false
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.indigo)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
                
                // Список результатів
                ZStack {
                    Color(.systemGroupedBackground).ignoresSafeArea()
                    
                    if vm.isLoading {
                        ProgressView("Завантаження...") // Текст змінив тут
                            .scaleEffect(1.2)
                    } else if let err = vm.errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(err).padding()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(vm.artworks) { art in
                                    NavigationLink(value: art) {
                                        ArtworkCard(art: art)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Музей")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Artwork.self) { art in
                DetailView(artwork: art, vm: vm)
            }
        }
    }
}

// Екран улюблених
struct FavoritesView: View {
    @ObservedObject var vm: ArtViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                if vm.favorites.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Колекція порожня")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(vm.favorites) { art in
                                NavigationLink(value: art) {
                                    ArtworkCard(art: art)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Моя Колекція")
            .navigationDestination(for: Artwork.self) { art in
                DetailView(artwork: art, vm: vm)
            }
        }
    }
}

// Картка твору (Дизайн)
struct ArtworkCard: View {
    let art: Artwork
    
    var body: some View {
        HStack(spacing: 15) {
            // Картинка
            if let thumb = art.primaryImageSmall, let url = URL(string: thumb) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color(.systemGray5)
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
                .clipped()
            } else {
                ZStack {
                    Color(.systemGray6)
                    Image(systemName: "photo").foregroundColor(.gray)
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
            }
            
            // Текст
            VStack(alignment: .leading, spacing: 5) {
                Text(art.title ?? "Без назви")
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(art.artistDisplayName ?? "Невідомий автор")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
}
