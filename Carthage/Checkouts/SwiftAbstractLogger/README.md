# SwiftAbstactLogger [![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/pryomoax/SwiftAbstractLogger/blob/master/LICENSE) [![GitHub release](https://img.shields.io/badge/version-v0.3.0-brightgreen.svg)](https://github.com/pryomoax/SwiftAbstractLogger/releases) ![Github stable](https://img.shields.io/badge/stable-true-brightgreen.svg)

Abstract, context-free logger for Swift packages. Permitting packages to implement logging without relying on a particular logging package, but leaving this to the consumer application.

# Package Management

## Installation
[![GitHub spm](https://img.shields.io/badge/spm-supported-brightgreen.svg)](https://swift.org/package-manager/)
[![GitHub carthage](https://img.shields.io/badge/carthage-supported-brightgreen.svg)](https://github.com/Carthage/Carthage)

### Using Swift Package Manager
SwiftAbstractLogger is available through [Swift Package Manager](https://swift.org/package-manager/). To install it, simply add the following line to your `Package.swift` dependencies:

```
.Package(url: "https://github.com/pryomoax/SwiftAbstractLogger.git", majorVersion: 0, minor: 3)
```

### Using Carthage
SwiftAbstractLogger is available through [Carthage](https://github.com/Carthage/Carthage). To install it, simply add the following line to your `Cartfile`:

```
# SwiftAbstractLogger
github "pryomoax/SwiftAbstractLogger.git" ~> 0.3
```

### Using CocoaPods

SwiftAbstractLogger is currently not supported by CocoaPods (coming soon)


# Usage

Any package using the **SwiftAbstractLogger** package will not log anything unless an application attached a logger. More than one logger can be attached to `Logger` if there is a need to support multiple loggers, say one to the console and another to the persisted resource.

## Logging

### Attaching Loggers

**SwiftAbstractLogger** contains a single default logger `BasicConsoleLogger` that can be attached.

```swift
Logger.attach(BasicConsoleLogger.logger)
```

Additional contirbution loggers can be attached in the same way

```swift
Logger.attach(MyLogger.logger)
```

### Logging 

Once a logger is attached, logging is as simple as using the convience logging function `log`.

```swift
log("Hello World")
```

Outputs the following log statement

```bash
Hello World
```

Logging other levels can be achieved by using the logging level convenice function `logCritical`|`Error`|`Warning`|`Info`|`Verbose`|`Debug`()

```swift
// Log debug statement
logDebug("Hello Debug World")
```

By default nothing will be logged with any logger attached because the default logging level is set to `.info` and `logDebug()` logs at the `.debug` level below the `Logger.defaultLevel` threshold.

```swift
// Set debug log level
Logger.defaultLevel = .debug

// Log debug statement
logDebug("Hello Debug World")
```

Outputs the following log statement

```bash
🐞 Hello Debug World
```

## Category Logging

Changing the global logging level for all logs isn't desirable. With **SwiftAbstractLogger** being used by potentially multiple packages, changing the levels would output too many logs. 

Category logging allows packages to scope logs and level to the package. Adding a `category` parameter to `log` or any level specialization, like `logDebug`. Scoping with categories permit log levels for that category to be configured independently.

```swift
// Set warning log level
Logger.defaultLevel = .warning

// Configure "MyCategory" to log at level Debug, below the global default level
Logger.configureLevel(category: "MyCategory", level: .debug)

logDebug("Global debug logging")
logDebug(category: "MyCategory", "MyCategory debug logging")
```

Outputs only the following logs

```bash
🐞 MyCategory debug logging
```

# Custom Loggers

Implementing additional loggers is as simple as extending `LoggerDelegate`. `BasicConsoleLogger` is an example of this, but can be implemented by many other loggers. 

There is only one function to implement to support a custom logger `log(level:category:message:)`. All other management is handled by the top level `Logger` class

```swift
public protocol LoggerDelegate {
	func log(level: Logger.LogLevel, category: String?, message: String)
}
```

All logging will be dispatched to the `main` dispatch queue. Any logger wanting to dispatch to another queue should be taken care of by the `LoggerDelegate` implementation.

# Package Information

## Requirements

* Xcode 8
* iOS 10.0+
* tvOS 10.0+
* watchOS 3.0+
* macOS 10.12+

## Author

Paul Bates, **[paul.a.bates@gmail.com](mailto:paul.a.bates@gmail.com)**

## License

AbstractLogger is available under the **MIT license**. See the `LICENSE` file for more info.
