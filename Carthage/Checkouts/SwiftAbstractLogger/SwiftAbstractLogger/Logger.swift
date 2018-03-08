//
//  Logger.swift
//  SwiftAbstractLogger
//
//  Created by Paul Bates on 2/4/17.
//  Copyright © 2017 Paul Bates. All rights reserved.
//

import Foundation

//
// MARK - Protocols
//

/// To be implemented by a logger to attach to a `Logger`
public protocol LoggerDelegate {
    /// Core logger function all logging is routed through
    ///
    /// - Parameter:
    ///     - level: Log level to log at
    ///     - category: Optional category to log at for filter
    ///     - message: Message to log
    func log(level: Logger.LogLevel, category: String?, message: String)
}

//
// MARK - Classes
//

/// Logger central coordinator. By default the logger does nothing until a logger implementing `LoggerDelegate` is associated by
/// calling `attach()`. 
///
/// Levels for the logger can be adjusted, set `defaultLevel`.
final public class Logger {
    public static var defaultLevel: LogLevel = .info

    /// Logging levels
    public enum LogLevel: Int {
        /// Critical, use only in exception cases
        case critial = 0
        /// Error, use for recoverable errors
        case error = 1
        /// Warning, use for warning conditions
        case warning = 2
        /// Information, use for all default logging
        case info = 3
        /// Verbose, use for verbose logs
        case verbose = 4
        /// Debug, use for very verbose, debug-only logs
        case debug = 5
    }
    
    /// Logs to the logger attached to the `Logger` instance
    ///
    /// - Parameter:
    ///     - level: Log level to log at (below `defaulLevel` will not be logged)
    ///     - category: Optional category to log at or filter by
    ///     - message: Message to log
    public class func log(level: LogLevel, category: String? = nil, message: String) {
        var categoryLevel: LogLevel?
        if category != nil {
            categoryLevel = categoryLevels[category!]
        }
        if categoryLevel == nil {
            categoryLevel = self.defaultLevel
        }
        
        if level.rawValue <= categoryLevel!.rawValue {
            if categoryLevel == nil || level.rawValue <= categoryLevel!.rawValue {
                // Ensure sync to main queue for logging
                DispatchQueue.main.async {
                    for delegate in loggers {
                        delegate.log(level: level, category: category, message: message)
                    }
                }
            }
        }
    }
    
    /// Attaches a logger implementation to the logger.
    ///
    /// - Parameters:
    ///     - logger: Logger implementation to attach to the logger
    public static func attach(_ logger: LoggerDelegate) {
        self.loggers.append(logger)
    }
    
    /// Configures logging level for a given category. 
    ///
    /// The level set for the cateogry will override `defaultLevel`.
    ///
    /// - Paramters:
    ///     - category: Category to configure
    ///     - level: Threshold level to log against
    public static func configureLevel(category: String, level: Logger.LogLevel) {
        self.categoryLevels[category] = level
    }
    
    //
    // MARK: Private implementation
    //
    
    private static var loggers: [LoggerDelegate] = []
    private static var categoryLevels: [String: Logger.LogLevel] = [:]
}

//
// MARK: -
//

// Default logging level string conversion
extension Logger.LogLevel: CustomStringConvertible {
    public var description: String {
        switch self {
        case .critial:
            return "Critical"
        case .error:
            return "Error"
        case .warning:
            return "Warning"
        case .info:
            return "Info"
        case .verbose:
            return "Verbose"
        case .debug:
            return "Debug"
        }
    }
}


//
// MARK: - Convenince functions
//

/// Convenince logging function
public func log(level: Logger.LogLevel = .info, category: String? = nil, _ message: String) {
    Logger.log(level: level, category: category, message: message)
}

/// Convenince critical level logging function.
///
/// Use only in exception cases
///
/// - Parameters:
///     - category: Optional category to log at, or filter by
///     - message: Message to log
public func logCritical(category: String? = nil, _ message: String) {
    Logger.log(level: .error, category: category, message: message)
}

/// Convenince error level logging function
///
/// Use for recoverable errors
///
/// - Parameters:
///     - category: Optional category to log at, or filter by
///     - message: Message to log
public func logError(category: String? = nil, _ message: String) {
    Logger.log(level: .error, category: category, message: message)
}

/// Convenince warning level logging function
///
/// Use for warning conditions
///
/// - Parameters:
///     - category: Optional category to log at, or filter by
///     - message: Message to log
public func logWarning(category: String? = nil, _  message: String) {
    Logger.log(level: .warning, category: category, message: message)
}

/// Convenince info level logging function
///
/// Use for all default logging
///
/// - Parameters:
///     - category: Optional category to log at, or filter by
///     - message: Message to log
public func logInfo(category: String? = nil, _  message: String) {
    Logger.log(level: .info, category: category, message: message)
}

/// Convenince verbose level logging function
///
/// Use for verbose logs
///
/// - Parameters:
///     - category: Optional category to log at, or filter by
///     - message: Message to log
public func logVerbose(category: String? = nil, _  message: String) {
    Logger.log(level: .verbose, category: category, message: message)
}

/// Convenince debug level logging function
///
/// Use for very verbose, debug-only logs
///
/// - Parameters:
///     - category: Optional category to log at, or filter by
///     - message: Message to log
public func logDebug(category: String? = nil, _  message: String) {
    Logger.log(level: .debug, category: category, message: message)
}
