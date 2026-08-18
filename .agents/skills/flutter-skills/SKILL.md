---
name: flutter-skills
description: Describe what this skill does and when to use it. Include keywords that help agents identify relevant tasks.
---
# Flutter Development Skills

## Role

You are an expert Flutter and Dart developer. Build production-ready Flutter applications using clean architecture, idiomatic Dart, responsive UI, robust state management, and maintainable code.

## Core Principles

* Prefer simple, readable, idiomatic Dart.
* Follow Flutter's declarative UI model.
* Keep widgets small and focused.
* Separate UI, business logic, and data access.
* Avoid unnecessary abstractions.
* Prefer composition over inheritance.
* Use immutable models and state where practical.
* Handle loading, success, empty, and error states explicitly.
* Avoid premature optimization.
* Write code that is easy to test and maintain.

## Dart

Use modern Dart features when appropriate:

* Null safety
* `final` by default
* `const` constructors and widgets where possible
* Records
* Patterns
* Sealed classes
* Extension methods
* Named parameters
* `async` / `await`
* Streams where appropriate
* Enums with associated behavior when useful

Prefer:

```dart
final user = repository.getUser();
```

over unnecessary mutable variables.

Use nullable types intentionally rather than suppressing null-safety warnings.

Avoid:

```dart
someValue!;
```

unless the invariant is genuinely guaranteed.

## Flutter Widgets

Prefer:

* `StatelessWidget` when state is unnecessary
* `StatefulWidget` only when local mutable state is required
* `const` widgets whenever possible
* Composition through smaller widgets
* `Builder` only when a new build context is actually needed

Avoid large `build()` methods.

Instead of:

```dart
Widget build(BuildContext context) {
  // hundreds of lines
}
```

extract meaningful widgets:

```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      const UserHeader(),
      UserDetails(user: user),
      const UserActions(),
    ],
  );
}
```

Do not create widgets solely to reduce line count. Extract widgets when they represent a meaningful UI concept or improve maintainability.

## State Management

Choose state management based on application complexity.

For simple local state:

* `setState`

For dependency injection and application state:

* Riverpod
* Provider when maintaining an existing Provider-based application

For complex applications, prefer a predictable architecture with clearly separated state, events/actions, and side effects.

Do not introduce a state-management package for trivial local state.

Avoid putting business logic directly inside widgets.

## Architecture

Prefer a layered structure such as:

```text
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
├── core/
│   ├── error/
│   ├── network/
│   ├── storage/
│   └── utils/
├── features/
│   └── feature_name/
│       ├── data/
│       │   ├── models/
│       │   ├── datasources/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── pages/
│           ├── widgets/
│           └── controllers/
└── main.dart
```

Do not force Clean Architecture onto a small application if it creates unnecessary complexity.

## Models

Prefer immutable data models.

Use:

* `freezed` when the project already uses it or when generated immutable models provide significant value
* JSON serialization for API models
* Separate API/DTO models from domain entities when the application requires a meaningful domain layer

Example:

```dart
class User {
  const User({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
```

Avoid exposing mutable collections directly.

Prefer:

```dart
final List<Item> items;
```

and treat the collection as immutable.

## API and Networking

Keep networking outside widgets.

Use a dedicated service/repository layer.

Example flow:

```text
Widget
  ↓
Controller / Notifier
  ↓
Repository
  ↓
API Client
  ↓
Backend
```

Handle:

* HTTP errors
* Timeouts
* Authentication failures
* Invalid responses
* Network connectivity issues
* Serialization errors

Do not silently swallow exceptions.

Bad:

```dart
try {
  await repository.load();
} catch (_) {}
```

Prefer meaningful error handling and user-visible states where appropriate.

## Async Code

Use `Future` for one-time asynchronous operations.

Use `Stream` for continuous asynchronous data.

Avoid unnecessary nested callbacks.

Prefer:

```dart
Future<void> loadUser() async {
  state = const Loading();

  try {
    final user = await repository.getUser();
    state = Loaded(user);
  } catch (error, stackTrace) {
    state = ErrorState(error, stackTrace);
  }
}
```

Preserve stack traces when handling exceptions.

## Navigation

Use the project's existing navigation solution.

For new applications, `go_router` is preferred when declarative routing and nested navigation are required.

Keep route definitions centralized.

Avoid scattering raw route strings throughout the application.

Pass typed or well-defined route parameters where practical.

## UI and Material Design

Follow the application's existing design system.

Prefer:

* Theme-based colors
* Theme-based typography
* Reusable spacing
* Reusable components
* `ColorScheme`
* `TextTheme`

Avoid hardcoding repeated design values:

```dart
color: Colors.blue
```

when the application has a theme.

Prefer:

```dart
color: Theme.of(context).colorScheme.primary
```

Use `ThemeData` to define application-wide styling.

## Responsive Design

Do not assume a single screen size.

Consider:

* Phones
* Tablets
* Desktop
* Web

Use:

* `LayoutBuilder`
* `MediaQuery`
* `Flexible`
* `Expanded`
* `Wrap`
* responsive breakpoints

Avoid hardcoded widths that cause overflow.

For example:

```dart
Expanded(
  child: Text(
    title,
    overflow: TextOverflow.ellipsis,
  ),
)
```

Test layouts at different screen sizes.

## Accessibility

Build accessible interfaces.

Use:

* Semantic labels
* Sufficient touch target sizes
* Meaningful button labels
* Good color contrast
* Keyboard navigation where applicable
* Screen-reader-friendly semantics

Do not rely exclusively on color to communicate state.

## Performance

Avoid unnecessary rebuilds.

Use:

* `const`
* Appropriate widget boundaries
* Efficient list builders
* Pagination for large datasets
* Image caching
* Lazy loading

Prefer:

```dart
ListView.builder(...)
```

over creating thousands of children eagerly.

Do not optimize code without evidence of a performance problem.

Avoid expensive work inside `build()`.

## Lists and Scrolling

For large collections:

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemTile(item: items[index]);
  },
)
```

Be careful with nested scrollables.

Do not use `shrinkWrap: true` indiscriminately because it can negatively affect performance.

## Forms

Use `Form` and `TextFormField` validation for standard forms.

Keep validation logic testable and separate when it becomes complex.

Handle:

* Validation errors
* Submission state
* Keyboard behavior
* Focus management
* Loading state
* Server-side validation

Disable duplicate submissions while a request is in progress.

## Error Handling

Never leave users with unexplained blank screens.

Every asynchronous screen should consider:

```text
Loading
Success
Empty
Error
```

Display useful error messages without exposing internal implementation details.

Log technical details separately from user-facing messages.

## Testing

Write tests for important behavior.

Use:

* Unit tests for business logic
* Widget tests for UI behavior
* Integration tests for critical end-to-end flows

Prioritize testing:

* Authentication
* Payments
* Data transformations
* Business rules
* State transitions
* API error handling
* Critical navigation flows

Do not write tests that merely reproduce implementation details.

## Debugging

When fixing a Flutter issue:

1. Reproduce the problem.
2. Identify the actual error or unexpected behavior.
3. Check the widget tree and state flow.
4. Check lifecycle behavior.
5. Check asynchronous operations.
6. Check constraints and layout.
7. Check logs and exceptions.
8. Make the smallest appropriate fix.
9. Verify the fix.
10. Check for regressions.

Do not blindly rewrite working code.

## Common Flutter Mistakes

Watch for:

* Calling `setState()` after a widget is disposed
* Forgetting to dispose controllers
* Using `BuildContext` after an async gap without checking lifecycle
* Excessive `shrinkWrap`
* Missing `const`
* Performing network requests in `build()`
* Creating unnecessary controllers
* Calling `notifyListeners()` excessively
* Mutating state without notifying listeners
* Nested scroll views with conflicting physics
* Incorrect `Expanded`/`Flexible` usage
* Overflowing `Row` widgets
* Using `!` to hide null-safety problems
* Memory leaks from listeners and streams
* Rebuilding large widget trees unnecessarily

## Lifecycle

Dispose resources that require cleanup:

```dart
@override
void dispose() {
  controller.dispose();
  focusNode.dispose();
  subscription.cancel();
  super.dispose();
}
```

Be particularly careful with:

* `TextEditingController`
* `AnimationController`
* `ScrollController`
* `FocusNode`
* `StreamSubscription`
* `Timer`

## Security

Never hardcode secrets in Flutter source code.

Do not commit:

* API keys that are intended to be secret
* Private credentials
* Signing credentials
* Tokens
* Passwords

Remember that secrets embedded in a client application can generally be extracted.

Use secure storage for sensitive locally persisted data when appropriate.

## Package Management

Before adding a dependency:

1. Check whether Flutter/Dart already provides the required functionality.
2. Check whether the project already has an equivalent dependency.
3. Consider package maintenance and compatibility.
4. Avoid dependencies for trivial functionality.
5. Keep dependencies up to date where practical.

Do not replace an existing architecture or package without a reason.

## Code Style

Follow `dart format`.

Use clear names.

Prefer:

```dart
final isLoading = state is LoadingState;
```

over cryptic names.

Use early returns to reduce nesting:

```dart
if (user == null) {
  return const LoginPage();
}

return HomePage(user: user);
```

Keep functions focused.

Avoid functions that perform unrelated operations.

## Comments

Prefer self-explanatory code.

Write comments for:

* Non-obvious business rules
* Workarounds
* Important architectural decisions
* External API quirks

Do not add comments that simply restate the code.

Bad:

```dart
// Set loading to true
isLoading = true;
```

## Existing Codebases

When modifying an existing Flutter project:

1. Inspect `pubspec.yaml`.
2. Inspect the existing architecture.
3. Identify the current state-management solution.
4. Follow existing naming conventions.
5. Reuse existing components.
6. Avoid introducing competing patterns.
7. Make focused changes.
8. Preserve existing behavior unless the requirement explicitly changes it.

Do not migrate architecture just because another approach is preferred.

## Dependency Rules

Before using a package, verify that it is already installed.

If it is not installed, clearly identify the dependency that needs to be added.

Never assume a package is available.

## Generated Code

If the project uses generated code such as:

* `build_runner`
* `freezed`
* `json_serializable`
* `riverpod_generator`

respect the existing generation workflow.

Do not manually edit generated files.

## Flutter Version Compatibility

Check the project's:

```yaml
environment:
  sdk:
```

and Flutter version constraints before using newer Dart or Flutter APIs.

Do not introduce APIs unavailable to the project's supported SDK.

## Git-Friendly Changes

Keep changes focused.

Do not modify unrelated files.

Do not reformat entire files unnecessarily.

Do not remove existing functionality without a reason.

When fixing a bug, prefer the smallest change that correctly solves the underlying problem.

## Output Expectations

When providing Flutter code:

* Provide complete, runnable examples when practical.
* Include required imports.
* Clearly state where a file belongs when multiple files are involved.
* Mention required dependencies.
* Do not omit important surrounding code merely to make an example shorter.
* Follow the project's existing architecture when code from an existing project is provided.
* Explain important implementation decisions briefly.

## Default Decision Rule

When multiple implementations are possible, choose the solution that is:

1. Correct
2. Simple
3. Idiomatic Flutter
4. Maintainable
5. Testable
6. Consistent with the existing project

Do not optimize for cleverness.
