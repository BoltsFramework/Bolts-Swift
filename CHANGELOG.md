# Change Log

## [1.4.0](https://github.com/BoltsFramework/Bolts-Swift/tree/1.4.0) (2018-07-19)
[Full Changelog](https://github.com/BoltsFramework/Bolts-Swift/compare/1.3.0...1.4.0)

**Implemented enhancements:**

- Remove flatMap because it is now deprecated in Swift 4.1 [\#71](https://github.com/BoltsFramework/Bolts-Swift/pull/71) ([sebleclerc](https://github.com/sebleclerc))
- Swift 4.0 Support [\#64](https://github.com/BoltsFramework/Bolts-Swift/pull/64) ([nlutsenko](https://github.com/nlutsenko))
- Adding a new executor which takes an escaping closure [\#58](https://github.com/BoltsFramework/Bolts-Swift/pull/58) ([sebleclerc](https://github.com/sebleclerc))

**Merged pull requests:**

- Changed casing of Executor enum value in README. [\#56](https://github.com/BoltsFramework/Bolts-Swift/pull/56) ([sjorsvb](https://github.com/sjorsvb))

## [1.3.0](https://github.com/BoltsFramework/Bolts-Swift/tree/1.3.0) (2016-09-20)
[Full Changelog](https://github.com/BoltsFramework/Bolts-Swift/compare/1.2.0...1.3.0)

**Implemented enhancements:**

- Add Swift 3.0 support. [\#40](https://github.com/BoltsFramework/Bolts-Swift/pull/40) ([nlutsenko](https://github.com/nlutsenko))

**Closed issues:**

- Swift 3.0 Support [\#33](https://github.com/BoltsFramework/Bolts-Swift/issues/33)

**Merged pull requests:**

- Update a TaskCompletionSource usage example for Swift 3.0. [\#48](https://github.com/BoltsFramework/Bolts-Swift/pull/48) ([sapzildj](https://github.com/sapzildj))
- Bolts 1.3.0 🔩 [\#42](https://github.com/BoltsFramework/Bolts-Swift/pull/42) ([nlutsenko](https://github.com/nlutsenko))
- Set lowest deployment macOS target to 10.10. [\#41](https://github.com/BoltsFramework/Bolts-Swift/pull/41) ([nlutsenko](https://github.com/nlutsenko))
- Fix README for TaskCompletionSource.cancel\(\) [\#37](https://github.com/BoltsFramework/Bolts-Swift/pull/37) ([ceyhuno](https://github.com/ceyhuno))

## [1.2.0](https://github.com/BoltsFramework/Bolts-Swift/tree/1.2.0) (2016-07-25)
[Full Changelog](https://github.com/BoltsFramework/Bolts-Swift/compare/1.1.0...1.2.0)

**Implemented enhancements:**

- Implement new set of continuations for error-only use case. [\#17](https://github.com/BoltsFramework/Bolts-Swift/issues/17)
- Make all 'trySet', 'set' functions to use explicit argument labels. [\#30](https://github.com/BoltsFramework/Bolts-Swift/pull/30) ([nlutsenko](https://github.com/nlutsenko))
- Update project/tests for Xcode 8 and Swift 2.3. [\#27](https://github.com/BoltsFramework/Bolts-Swift/pull/27) ([nlutsenko](https://github.com/nlutsenko))
- Make CompletedCondtion optional, should improve memory usage slightly. [\#25](https://github.com/BoltsFramework/Bolts-Swift/pull/25) ([richardjrossiii](https://github.com/richardjrossiii))
- Add continueOnErrorWith, continueOnErrorWithTask. [\#18](https://github.com/BoltsFramework/Bolts-Swift/pull/18) ([nlutsenko](https://github.com/nlutsenko))

**Fixed bugs:**

- Resolve retain cycle in Task [\#19](https://github.com/BoltsFramework/Bolts-Swift/pull/19) ([mmtootmm](https://github.com/mmtootmm))

**Merged pull requests:**

- Refactor continuation to be better, faster, stronger. [\#20](https://github.com/BoltsFramework/Bolts-Swift/pull/20) ([richardjrossiii](https://github.com/richardjrossiii))
- Bolts 1.2.0 🔩 [\#34](https://github.com/BoltsFramework/Bolts-Swift/pull/34) ([nlutsenko](https://github.com/nlutsenko))
- Migrate all targets to shared configurations from xctoolchain. [\#32](https://github.com/BoltsFramework/Bolts-Swift/pull/32) ([nlutsenko](https://github.com/nlutsenko))
- Add swiftlint to Travis-CI. [\#29](https://github.com/BoltsFramework/Bolts-Swift/pull/29) ([nlutsenko](https://github.com/nlutsenko))
- Split Task into multiple files. [\#24](https://github.com/BoltsFramework/Bolts-Swift/pull/24) ([richardjrossiii](https://github.com/richardjrossiii))
- Update installation instructions in README. [\#22](https://github.com/BoltsFramework/Bolts-Swift/pull/22) ([nlutsenko](https://github.com/nlutsenko))

## [1.1.0](https://github.com/BoltsFramework/Bolts-Swift/tree/1.1.0) (2016-05-04)
[Full Changelog](https://github.com/BoltsFramework/Bolts-Swift/compare/1.0.1...1.1.0)

**Implemented enhancements:**

- Add ability to throw errors in all Task continuations that return a Task. [\#14](https://github.com/BoltsFramework/Bolts-Swift/pull/14) ([nlutsenko](https://github.com/nlutsenko))
- Improve and add missing documentation. [\#10](https://github.com/BoltsFramework/Bolts-Swift/pull/10) ([nlutsenko](https://github.com/nlutsenko))

**Fixed bugs:**

- Fix usage of CancelledError, add tests for error handling inside tasks. [\#13](https://github.com/BoltsFramework/Bolts-Swift/pull/13) ([nlutsenko](https://github.com/nlutsenko))

**Merged pull requests:**

- Bolts 1.1.0 🔩 [\#16](https://github.com/BoltsFramework/Bolts-Swift/pull/16) ([nlutsenko](https://github.com/nlutsenko))
- Add more tests and fix documentation. [\#12](https://github.com/BoltsFramework/Bolts-Swift/pull/12) ([nlutsenko](https://github.com/nlutsenko))
- Use Xcode 7.3 for Travis-CI. [\#11](https://github.com/BoltsFramework/Bolts-Swift/pull/11) ([nlutsenko](https://github.com/nlutsenko))

## [1.0.1](https://github.com/BoltsFramework/Bolts-Swift/tree/1.0.1) (2016-03-24)
[Full Changelog](https://github.com/BoltsFramework/Bolts-Swift/compare/1.0.0...1.0.1)

**Implemented enhancements:**

- Make tests less flaky and be able to run under Swift 2.2/Xcode 7.3. [\#1](https://github.com/BoltsFramework/Bolts-Swift/pull/1) ([nlutsenko](https://github.com/nlutsenko))

**Fixed bugs:**

- Task never completes [\#5](https://github.com/BoltsFramework/Bolts-Swift/issues/5)
- Fix optimized away TaskCompletionSource non-try methods. [\#7](https://github.com/BoltsFramework/Bolts-Swift/pull/7) ([nlutsenko](https://github.com/nlutsenko))

**Merged pull requests:**

- Bolts 1.0.1 🔩 [\#9](https://github.com/BoltsFramework/Bolts-Swift/pull/9) ([nlutsenko](https://github.com/nlutsenko))
- Add tests for release configuration in addition to Debug one. [\#8](https://github.com/BoltsFramework/Bolts-Swift/pull/8) ([nlutsenko](https://github.com/nlutsenko))
- Use common expectation wait method in tests. [\#6](https://github.com/BoltsFramework/Bolts-Swift/pull/6) ([nlutsenko](https://github.com/nlutsenko))
- README: Fix syntax in example code. [\#4](https://github.com/BoltsFramework/Bolts-Swift/pull/4) ([Lukas-Stuehrk](https://github.com/Lukas-Stuehrk))
- Fix typo in README. [\#3](https://github.com/BoltsFramework/Bolts-Swift/pull/3) ([Lukas-Stuehrk](https://github.com/Lukas-Stuehrk))
- Fix typos in README [\#2](https://github.com/BoltsFramework/Bolts-Swift/pull/2) ([richardjrossiii](https://github.com/richardjrossiii))

## [1.0.0](https://github.com/BoltsFramework/Bolts-Swift/tree/1.0.0) (2016-03-17)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*