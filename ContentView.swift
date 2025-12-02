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
            
            // Вкладка 2: Моя Колекція
            FavoritesView(vm: vm)
                .tabItem {
                    Label("Колекція", systemImage: "star.fill")
                }
        }
    }
}

// Виніс екран пошуку в окремий View для чистоти
struct SearchView: View {
    @ObservedObject var vm: ArtViewModel
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Пошук (напр. Van Gogh)...", text: $vm.query)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .onSubmit { Task { await vm.search() } }
                        .focused($isFocused)
                    
                    Button {
                        Task { await vm.search() }
                        isFocused = false
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()

                if vm.isLoading {
                    ProgressView("Завантаження...")
                } else if let err = vm.errorMessage {
                    Text(err).foregroundColor(.red).padding()
                }

                List(vm.artworks) { art in
                    NavigationLink(value: art) {
                        ArtworkRow(art: art)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Музей")
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
            List(vm.favorites) { art in
                NavigationLink(value: art) {
                    ArtworkRow(art: art)
                }
            }
            .navigationTitle("Моя Колекція")
            .overlay {
                if vm.favorites.isEmpty {
                    Text("Поки що тут порожньо")
                        .foregroundColor(.gray)
                }
            }
            .navigationDestination(for: Artwork.self) { art in
                DetailView(artwork: art, vm: vm)
            }
        }
    }
}

// Окремий рядок списку, щоб не дублювати код
struct ArtworkRow: View {
    let art: Artwork
    
    var body: some View {
        HStack {
            if let thumb = art.primaryImageSmall, let url = URL(string: thumb) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(6)
                .clipped()
            } else {
                Color.gray.frame(width: 60, height: 60).cornerRadius(6)
            }
            
            VStack(alignment: .leading) {
                Text(art.title ?? "Без назви")
                    .font(.headline)
                    .lineLimit(2)
                Text(art.artistDisplayName ?? "Невідомий")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
