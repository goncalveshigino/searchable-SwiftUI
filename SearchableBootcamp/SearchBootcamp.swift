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
    @Published var searchScope: SearchScopeOption = .all
    @Published private(set) var allSearchScope: [SearchScopeOption] = []
    
    
    let manager = RestaurantManager()
    private var cancellables = Set<AnyCancellable>()
    
    var isSearching: Bool {
        !searchText.isEmpty
    }
    
    enum SearchScopeOption: Hashable {
        case all
        case cuisine(option: CuisineOption)
        
        var title: String {
            switch self {
            case .all:
                return "All"
            case .cuisine(option: let option):
                return option.rawValue.capitalized
            }
        }
    }
    
    init() {
        addSubscribers()
    }
    
    private func addSubscribers() {
        $searchText
            .combineLatest($searchScope)
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] (searchText, searchScope) in
                self?.filterRestaurants(searchText: searchText, currentSearchScope: searchScope)
            }
            .store(in: &cancellables)
    }
    
    
    
    private func filterRestaurants(searchText: String, currentSearchScope: SearchScopeOption) {
        guard !searchText.isEmpty else {
            filteredRestaurants = []
            searchScope = .all
            return
        }
        
        //Filter on search scope
        var restaurantInScope = allRestaurants
        switch currentSearchScope {
        case .all:
            break
        case .cuisine(let option):
            restaurantInScope = allRestaurants.filter({ $0.cuisine == option })
        }
        
        
        // Filter on search text
        let search = searchText.lowercased()
        filteredRestaurants = restaurantInScope.filter({ restaurant in
            let titleContainsSearch = restaurant.title.lowercased().contains(search)
            let cuisineContainsSearch = restaurant.cuisine.rawValue.lowercased().contains(search)
            
            return titleContainsSearch || cuisineContainsSearch
        })
    }
    
    func loadRestaurants() async {
        do {
           allRestaurants = try await manager.getAllRestaurants()
            
            let allCuisines = Set(allRestaurants.map { $0.cuisine })
            allSearchScope = [.all] + allCuisines.map({ SearchScopeOption.cuisine(option: $0)})
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
                
//                Text("ViewModel is searching: \(viewModel.isSearching.description)")
//                searchChildView()
            }
            .searchable(text: $viewModel.searchText, placement: .automatic, prompt: Text("Search restaurants..."))
            .searchScopes($viewModel.searchScope, scopes: {
                ForEach(viewModel.allSearchScope, id: \.self) { scope in
                    Text(scope.title)
                        .tag(scope)
                }
            })
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


struct searchChildView: View {
    @Environment(\.isSearching) private var isSearching
    
    var body: some View {
        Text("Chil view is searching: \(isSearching.description)")
    }
}

#Preview {
    NavigationStack {
        SearchBootcamp()
    }
}
