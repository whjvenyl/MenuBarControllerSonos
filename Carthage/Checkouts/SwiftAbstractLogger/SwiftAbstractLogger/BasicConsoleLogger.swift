//
//  BasicConsoleLogger.swift
//  SwiftAbstractLogger
//
//  Created by Paul Bates on 2/4/17.
//  Copyright © 2017 Paul Bates. All rights reserved.
//

import Foundation

/// Basic default console logger
final public class BasicConsoleLogger: LoggerDelegate {
    
    /// Singleton access
    public static var logger = BasicConsoleLogger()
    
    /// No public initialization
    private init() {
        
    }

    //
    // MARK: LoggerDelegate functions
    //
    
    public func log(level: Logger.LogLevel, category: String?, message: String) {
        if let categoryName = category, !categoryName.isEmpty {
            print("\(logLevelNames[level]!)(\(categoryName)): \(message)")
        } else {
            print("\(logLevelNames[level]!): \(message)")
        }
    }
    
    //
    // MARK: Private implementation
    //
    
    /// Maps `LogLevel` to a console printable log name
    private var logLevelNames: [Logger.LogLevel: String] = [
        .critial: "💣 Critical",
        .error: "😡 Error",
        .warning: "⚠️ Warning",
        .info: "Info",
        .verbose: "Verbose",
        .debug: "🐞 Debug"
    ]
}
