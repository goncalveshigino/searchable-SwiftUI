//
//  ContentView.swift
//  SearchableBootcamp
//
//  Created by Goncalves Higino on 19/12/23.
//

import SwiftUI
import Combine

struct Restaurant: Identifiable, Hashable {
    let id: String
    let title: String
    let cuisine: CuisineOption
}

enum CuisineOption: String {
    case american, italian, japanese, angolana
}

final class RestaurantManager {
    
    func getAllRestaurants() async throws -> [Restaurant] {
        [
            Restaurant(id: "1", title: "Burger Shack", cuisine: .american),
            Restaurant(id: "2", title: "Moça Fina", cuisine: .angolana),
            Restaurant(id: "3", title: "ありがとう", cuisine: .japanese),
            Restaurant(id: "4", title: "JulioPerro", cuisine: .italian),
        
        ]
    }
    
}

@MainActor
final class SearchableViewModel: ObservableObject {
    
    
    @Published private(set) var allRestaurants: [Restaurant] = []
    @Published private(set) var filteredRestaurants: [Restaurant] = []
    @Published var searchText: String = ""
    let manager = RestaurantManager()
    private var cancellables = Set<AnyCancellable>()
    
    var isSearching: Bool {
        !searchText.isEmpty
    }
    
    init() {
        addSubscribers()
    }
    
    private func addSubscribers() {
        $searchText
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.filterRestaurants(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    private func filterRestaurants(searchText: String) {
        guard !searchText.isEmpty else {
            filteredRestaurants = []
            return
        }
        
        let search = searchText.lowercased()
        filteredRestaurants = allRestaurants.filter({ restaurant in
            let titleContainsSearch = restaurant.title.lowercased().contains(search)
            let cuisineContainsSearch = restaurant.cuisine.rawValue.lowercased().contains(search)
            
            return titleContainsSearch || cuisineContainsSearch
        })
    }
    
    func loadRestaurants() async {
        do {
           allRestaurants = try await manager.getAllRestaurants()
        } catch  {
            print(error)
        }
    }
    
}

struct SearchBootcamp: View {
    
    @StateObject private var viewModel = SearchableViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(viewModel.isSearching ? viewModel.filteredRestaurants : viewModel.allRestaurants) { restaurant in
                    restaurantRow(restaurant: restaurant)
                }
                .padding()
            }
            .searchable(text: $viewModel.searchText, placement: .automatic, prompt: Text("Search restaurants..."))
            .navigationTitle("Restaurantes")
            .task {
                await viewModel.loadRestaurants()
           }
        }
    }
    
    private func restaurantRow(restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(restaurant.title)
                .font(.headline)
            Text(restaurant.cuisine.rawValue.capitalized)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.05))
    }
}

#Preview {
    NavigationStack {
        SearchBootcamp()
    }
}
