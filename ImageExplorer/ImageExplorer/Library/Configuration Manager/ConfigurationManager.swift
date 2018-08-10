//
//  ConfigurationManager.swift
//
//  Created by Rishi Kumar on 08/08/18.
//  Copyright © 2018 Rishi Kumar. All rights reserved.
//

import UIKit

final class ConfigurationManager: NSObject {
    
    /*
     Open your Project Build Settings and search for “Swift Compiler – Custom Flags” … “Other Swift Flags”.
     Add “-DDEVELOPMENT” to the Debug section
     Add “-DPRODUCTION” to the Release section
     */
    fileprivate enum AppEnvironment: String {
        case Development
        case Production
    }
    
    fileprivate struct AppConfiguration {
        var apiEndPoint: String
        var loggingEnabled: Bool
        var environment: AppEnvironment
    }
    
    fileprivate var activeConfiguration: AppConfiguration!
    
    var environment: NSDictionary!
    
    // MARK: - Singleton Instance
    private static let _sharedManager = ConfigurationManager()
    
    class func sharedManager() -> ConfigurationManager {
        return _sharedManager
    }
    
    private override init() {
        super.init()
        // customize initialization
        initialize()
    }
    
    // MARK: Private Method
    private func initialize() {
        
        // Load application selected environment and its configuration
        if let environment = self.currentEnvironment() {
            
            activeConfiguration = configuration(environment: environment)
            
            if activeConfiguration == nil {
                assertionFailure(NSLocalizedString("Unable to load application configuration", comment: "Unable to load application configuration"))
            }
        } else {
            assertionFailure(NSLocalizedString("Unable to load application flags", comment: "Unable to load application flags"))
        }
    }
    
    private func currentEnvironment() -> AppEnvironment? {
        
        #if PRODUCTION
        return AppEnvironment.Production
        #else // Default configuration DEVELOPMENT
        return AppEnvironment.Development
        #endif
        
        /* let environment = Bundle.main.infoDictionary?["ActiveConfiguration"] as? String
         return environment */
    }
    
    /**
     Returns application active configuration
     
     - parameter environment: An application selected environment
     
     - returns: An application configuration structure based on selected environment
     */
    private func configuration(environment: AppEnvironment) -> AppConfiguration {
        
        switch environment {
        case .Development:
            return debugConfiguration()
        case .Production:
            return productionConfiguration()
        }
    }
    
   
   
    private func debugConfiguration() -> AppConfiguration {
        return AppConfiguration(apiEndPoint: "https://api.flickr.com/services",
                                loggingEnabled: true,
                                environment: .Development)
    }
    
    // TODO: Please change the key values
    private func productionConfiguration() -> AppConfiguration {
        return AppConfiguration(apiEndPoint: "https://api.flickr.com/services",
                                loggingEnabled: true,
                                environment: .Development)
    }
    
    // MARK: - Public Methods
    
    func applicationEnvironment() -> String {
        return activeConfiguration.environment.rawValue
    }
    
    func applicationEndPoint() -> String {
        return activeConfiguration.apiEndPoint
    }
    
   
    
    func loggingEnabled() -> Bool {
        return activeConfiguration.loggingEnabled
    }
    
}
