//
//  SwiftDataService.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 21/11/2026.
//

import SwiftData

/// Provides fetch, insertion, and deletion operations for one SwiftData model type.
///
/// The service retains its model container and uses the container's main context
/// for every operation. It doesn't keep a separate cache of fetched models. The
/// main context tracks changes to fetched models and automatically saves pending
/// inserts, updates, and deletes.
@MainActor
struct SwiftDataService<Model: PersistentModel> {
    
    // MARK: - Properties
    
    /// The retained container whose main context performs this service's operations.
    private let modelContainer: ModelContainer
    
    // MARK: - Init

    /// Creates a service that retains the container used for its operations.
    /// - Parameter modelContainer: The container whose main context manages the models.
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // MARK: - Methods

    /// Fetches models matching the descriptor.
    /// - Parameter descriptor: The criteria and sort order for the fetch.
    /// - Returns: The models matching the descriptor.
    /// - Throws: An error if SwiftData can't perform the fetch.
    func fetch(
        _ descriptor: FetchDescriptor<Model> = FetchDescriptor<Model>()
    ) throws -> [Model] {
        try modelContainer.mainContext.fetch(descriptor)
    }

    /// Registers a model for insertion into the context.
    /// - Parameter model: The model to insert.
    func insert(_ model: Model) {
        modelContainer.mainContext.insert(model)
    }

    /// Registers a model for deletion from the context.
    /// - Parameter model: The model to delete.
    func delete(_ model: Model) {
        modelContainer.mainContext.delete(model)
    }
}
