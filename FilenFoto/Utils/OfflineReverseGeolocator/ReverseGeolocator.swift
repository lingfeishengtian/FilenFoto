//
//  ReverseGeolocator.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/12/24.
//

import Foundation
import SQLite

class ReverseGeolocator {
    static let shared = ReverseGeolocator()
    
    private init() {}
    
    // Under same folder Cities.db
    private let databaseConnection = try! Connection(Bundle.main.bundleURL.appendingPathComponent("Cities.db").path)
    
    private typealias Expression = SQLite.Expression
    private var worldCitiesTable = Table("worldcities")
    private var cityColumn = Expression<String>("city")
    private var cityAsciiColumn = Expression<String>("city_ascii")
    private var latColumn = Expression<Double>("lat")
    private var lngColumn = Expression<Double>("lng")
    private var countryColumn = Expression<String>("country")
    private var iso2Column = Expression<String>("iso2")
    private var iso3Column = Expression<String>("iso3")
    private var adminNameColumn = Expression<String>("admin_name")
    private var capitalColumn = Expression<String>("capital")
    private var populationColumn = Expression<Int>("population")
    
    /// Returns city name, country name, and admin name (state) of the given latitude and longitude
    func reverseGeolocate(latitude: Double, longitude: Double) -> (cityName: String, adminName: String, countryName: String)? {
        let query = worldCitiesTable.order(
            (latitude - worldCitiesTable[latColumn]) * (latitude - worldCitiesTable[latColumn]) +
            (longitude - worldCitiesTable[lngColumn]) * (longitude - worldCitiesTable[lngColumn])
        ).limit(1)
        
        guard let row = try? databaseConnection.pluck(query) else {
            return nil
        }
        
        return (row[cityColumn], row[countryColumn], row[adminNameColumn])
    }
}
