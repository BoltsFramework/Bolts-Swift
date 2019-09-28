# Bolts in Swift

![Platforms][platforms-svg]
![Swift Version][swift-version-svg]

[![Podspec][podspec-svg]][podspec-link]
[![Carthage compatible][carthage-svg]](carthage-link)
[![Swift Package Manager compatible](swiftpm-svg)](swiftpm-link)
[![License][license-svg]][license-link]

[![Build Status][build-status-svg]][build-status-link]
[![Coverage Status][coverage-status-svg]][coverage-status-link]

Bolts is a collection of low-level libraries designed to make developing mobile apps easier. Bolts was designed by Parse and Facebook for our own internal use, and we have decided to open source these libraries to make them available to others.

## Tasks

Bolts Tasks is a complete implementation of futures/promises for iOS/OS X/watchOS/tvOS and any platform that supports Swift.
A task represents the result of an asynchronous operation, which typically would be returned from a function.
In addition to being able to have different states `completed`/`faulted`/`cancelled` they provide these benefits:

- `Tasks` consume fewer system resources, since they don't occupy a thread while waiting on other `Tasks`.
- `Tasks` could be performed/chained in a row which will not create nested "pyramid" code as you would get when using only callbacks.
- `Tasks` are fully composable, allowing you to perform branching, parallelism, and complex error handling, without the spaghetti code of having many named callbacks.
- `Tasks` allow you to arrange code in the order that it executes, rather than having to split your logic across scattered callback functions.
- `Tasks` don't depend on any particular threading model. So you can use concepts like operation queues/dispatch queues or even thread executors.
- `Tasks` could be used synchronously or asynchronously, providing the same benefit of different results of any function/operation.

## Getting Started

- **[CocoaPods](https://cocoapods.org)**

 Add the following line to your Podfile:

 ```ruby
 pod 'Bolts-Swift'
 ```

 Run `pod install`, and you should now have the latest parse release.

- **[Carthage](https://github.com/carthage/carthage)**

 Add the following line to your Cartfile:

 ```
 github "BoltsFramework/Bolts-Swift"
 ```

 Run `carthage update`, and you should now have the latest version of Bolts in your Carthage folder.

- **Using Bolts as a sub-project**

  You can also include Bolts as a subproject inside of your application if you'd prefer, although we do not recommend this, as it will increase your indexing time significantly. To do so, just drag and drop the `BoltsSwift.xcodeproj` file into your workspace.

- **Import Bolts**

  Now that you have the framework linked to your application - add the folowing line in every `.swift` that you want to use Bolts from:

  ```
  import BoltsSwift
  ```

## Chaining Tasks

There are special methods you can call on a task which accept a closure argument and will return the task object. Because they return tasks it means you can keep calling these methods – also known as _chaining_ – to perform logic in stages. This is a powerful approach that makes your code read as a sequence of steps, while harnessing the power of asynchronous execution. Here are 3 key functions you should know:

1. Use `continueWith` to inspect the task after it has ran and perform more operations with the result
1. Use `continueWithTask` to add more work based on the result of the previous task
1. Use `continueOnSuccessWith` to perform logic only when task executed without errors

For full list of available methods please see source code at **[Task+ContinueWith.swift][continueWith-source]**

### continueWith

Every `Task` has a function named `continueWith`, which takes a continuation closure. A continuation will be executed when the task is complete. You can the inspect the task to check if it was successful and to get its result.

```swift
save(object).continueWith { task in
  if task.cancelled {
    // Save was cancelled
  } else if task.faulted {
    // Save failed
  } else {
    // Object was successfully saved
    let result = task.result
  }
}
```

### continueOnSuccessWith

In many cases, you only want to do more work if the previous task was successful, and propagate any error or cancellation to be dealt with later. To do this, use `continueOnSuccessWith` function:

```swift
save(object).continueOnSuccessWith { result in
  // Closure receives the result of a succesfully performed task
  // If result is invalid throw an error which will mark task as faulted
}
```

Underneath, `continueOnSuccessWith` is calling `continueOnSuccessWithTask` method which is more powerful and useful for situations where you want to spawn additional work.

### continueOnSuccessWithTask

As you saw above, if you return an object from `continueWith` function – it will become a result the Task. But what if there is more work to do? If you want to call into more tasks and return their results instead – you can use `continueWithTask`. This gives you an ability to chain more asynchronous work together.

In the following example we want to fetch a user profile, then fetch a profile image, and if any of these operations failed - we still want to display an placeholder image:

```swift
fetchProfile(user).continueOnSuccessWithTask { task in
  return fetchProfileImage(task.result);
}.continueWith { task in
  if let image = task.result {
    return image
  }
  return ProfileImagePlaceholder()
}
```

## Creating Tasks

To create a task - you would need a `TaskCompletionSource`, which is a consumer end of any `Task`, which gives you an ability to control whether the task is completed/faulted or cancelled.
After you create a `TaskCompletionSource`, you need to call `setResult()`/`setError()`/`cancel()` to trigger its continuations and change its state.

```swift
func fetch(object: PFObject) -> Task<PFObject> {
  let taskCompletionSource = TaskCompletionSource<PFObject>()
  object.fetchInBackgroundWithBlock() { (object: PFObject?, error: NSError?) in
    if let error = error {
      taskCompletionSource.setError(error)
    } else if let object = object {
      taskCompletionSource.setResult(object)
    } else {
      taskCompletionSource.cancel()
    }
  }
  return taskCompletionSource.task
}
```

## Tasks in Parallel

You can also perform several tasks in parallel and chain the result of all of them using `whenAll()` function.

```swift
let query = PFQuery(className: "Comments")
find(query).continueWithTask { task in
  var tasks: [Task<PFObject>] = []
  task.result?.forEach { comment in
    tasks.append(self.deleteComment(comment))
  }
  return Task.whenAll(tasks)
}.continueOnSuccessWith { task in
  // All comments were deleted
}
```

## Task Executors

Both `continueWith()` and `continueWithTask()` functions accept an optional executor parameter. It allows you to control how the continuation closure is executed.
The default executor will dispatch to global dispatch queue, but you can provide your own executor to schedule work in a specific way.
For example, if you want to continue with work on the main thread:

```swift
fetch(object).continueWith(Executor.mainThread) { task in
  // This closure will be executor on the main application's thread
}
```

## How Do I Contribute?

We want to make contributing to this project as easy and transparent as possible. Please refer to the [Contribution Guidelines][contributing].

 [releases]: https://github.com/BoltsFramework/Bolts-Swift/releases
 [contributing]: https://github.com/BoltsFramework/Bolts-Swift/blob/master/CONTRIBUTING.md

 [build-status-svg]: https://img.shields.io/travis/BoltsFramework/Bolts-Swift/master.svg
 [build-status-link]: https://travis-ci.org/BoltsFramework/Bolts-Swift/branches

 [coverage-status-svg]: https://img.shields.io/codecov/c/github/BoltsFramework/Bolts-Swift/master.svg
 [coverage-status-link]: https://codecov.io/github/BoltsFramework/Bolts-Swift?branch=master

 [license-svg]: https://img.shields.io/badge/license-BSD-lightgrey.svg
 [license-link]: https://github.com/BoltsFramework/Bolts-Swift/blob/master/LICENSE

 [podspec-svg]: https://img.shields.io/cocoapods/v/Bolts-Swift.svg
 [podspec-link]: https://cocoapods.org/pods/Bolts-Swift

 [carthage-svg]: https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat
 [carthage-link]: https://github.com/carthage/carthage

 [swiftpm-svg]: https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg?style=flat
 [swiftpm-link]: https://github.com/apple/swift-package-manager

 [platforms-svg]: http://img.shields.io/cocoapods/p/Bolts-Swift.svg?style=flat
 [swift-version-svg]: https://img.shields.io/badge/Swift-5-orange.svg

 [continueWith-source]: https://github.com/BoltsFramework/Bolts-Swift/blob/master/Sources/BoltsSwift/Task%2BContinueWith.swift
