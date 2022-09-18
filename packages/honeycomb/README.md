<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

Smart Service Locator

### Navigation
- [How is it different from Riverpod?](#how-is-it-different-from-riverpod)
- [Getting started](#getting-started)
- [Features](#features)
  - [Providers](#providers)
    - [Injecting providers](#injecting-providers)
    - [Disposing providers](#disposing-providers)
  - [Overrides](#overrides)
    - [Example](#example)
  - [Scopes](#scopes)
    - [Dependencies*](#dependencies)
- [Benchmark comparison](#benchmark-comparison)
- [Is it production ready?](#is-it-production-ready)
- [Credits](#credits)

## How is it different from Riverpod?

* It's not a state management solution
* Only 2 provider types
* You can scope providers, but overrides are only available globally
* Providers are scoped automatically if one of their dependencies is also scoped.
  
## Getting started

Define provider as global variable
```dart
class Counter {
    final int count = 0;
}

final counterProvider = Provider((read) => Counter());
```

Create container - it holds all providables
```dart
final container = ProviderContainer();
```

Read provider
```dart 
void main() {
    /// Counter is created lazily and cached inside container
    final counter = container.read(counterProvider)
    final sameCounter = container.read(counterProvider)

    print(counter == sameCounter) // true
    print(counter.count) // 0
}
```

## Features

### Providers
There are 2 types of Providers in `honeycomb`:
```dart
class Counter {}
class UserViewModel {
    final int userId;
    UserViewModel(this.userId);
}

// Provider
final counterProvider = Provider((_) => Counter());

// Factory provider
final userVmProvider = Provider.factory(
    (_, int userId) => UserViewModel(userId),
);
```

The difference between these two is that `Provider.factory` creates providers, while usual providers are self-contained.

Consider `Provider` usage:
```dart
container.read(counterProvider) // Counter instance
```

And `Provider.factory`:
```dart
final user100Provider = userVmProvider(100);
container.read(user100Provider);
```
or just:
```dart
container.read(userVmProvider(100)) // UserVM.userId === 100
```

#### Injecting providers
```dart
final cartRepositoryProvider = Provider(
    (_) => CartRepository(),
);

final cartViewModelProvider = Provider.factory((read, int cartId) {
    final repository = read(cartRepository);
    return CartViewModel(
        repository: repository,
        cartId: cartId,
    );
})
```

#### Disposing providers
```dart
final cartViewModelProvider = Provider(
    (read) =>  CartViewModel(...),
    dispose: (CartViewModel vm) => vm.dispose(),
);
```

Container has `dispose` method, which disposes all providers within it.
```dart
container.dispose();
```

### Overrides

You can override any provider with any other provider of compatible type.
```dart
    final container = ProviderContainer(
        overrides: [
            userRepositoryProvider.overrideWith(mockUserRepositoryProvider)
        ]
    );

    container.read(userRepositoryProvider) // MockUserRepository
```

#### Example
Consider this:
```dart
class UserRepository {
    User getById(int id) {
        return User(id: id, isAdmin: false);
    }
}

class UserProfileViewModel {
    final UserRepository repository;
    final int userId;
    
    UserProfileViewModel({
        required this.repository, 
        required this.userId,
    });

    String get isAdmin => repository.getById(userId).isAdmin;
}

final userRepositoryProvider = Provider(
    (_) => UserRepository(),
);

final userProfileVmProvider = Provider.factory(
    (read, int userId) => UserProfileViewModel(
        userId: userId,
        repository: read(userRepositoryProvider),
    )
);
```

Here is the task: mock UserRepository, so getById always returns admin user.
Easy:
```dart
class MockUserRepository implements UserRepository {
    User getById(int id) {
        return User(id: id, isAdmin: true);
    }
}


final mockRepositoryProvider = Provider<UserRepository>(() => MockUserRepository());

final containerWithOverride = ProviderContainer(
    overrides: [
        userRepositoryProvider.overrideWith(mockRepositoryProvider),
    ],
);


void main() {
    final profileVm = containerWithOverride.read(userProfileVmProvider(1));
    print(profileVm.isAdmin) // true
}
```

### Scopes
Providers can be scoped:
```dart
final userProvider = Provider((_) => User(...));
final containerRoot = ProviderContainer();
final containerChild = ProviderContainer.scoped(
    [userProvider],
    parent: containerRoot,
);

void main() {
    final rootUser = containerRoot.read(userProvider);
    final childUser = containerChild.read(userProvider);

    identical(rootUser, childUser); // false
}
```

Provider becomes scoped, if any of it's dependencies* gets scoped.
Consider this example:
```dart
class Counter {
    final int count;
    Counter(this.count);
}

final provider1 = Provider((_) => Counter(1));
final provider2 = Provider((read) => Counter(read(provider1).count + 1));
final provider3 = Provider((read) => Counter(read(provider2).count + 3));


final container = ProviderContainer();
final containerChild = ProviderContainer.scoped(
    [provider2],
    parent: container, 
);

void main() {
    // now provider3 also scoped inside containerChild
    final instance3 = containerChild.read(provider3); 
    final rootInstance3 = container.read(provider3);

    identical(instance3, rootInstance3); // false


    final instance1 = containerChild.read(provider1);
    final rootInstance1 = container.read(provider1);

    // provider1 doesn't have scoped dependencies, so it doesn't become scoped.
    identical(instance1, rootInstance1); // true
}
```

#### Dependencies*
```dart
final provider1 = Provider((_) => Counter(1));
final provider2 = Provider((read) => Counter(read(provider1).count + 1));
final provider3 = Provider((read) => Counter(read(provider2).count + 3));
```

* `provider1` has **no dependencies**<br>
* `provider2` has **single dependency** - on `provider1`.<br>
* `provider3` has **2 dependencies**:
>* direct dependency on `provider2`
>* transitive dependency on `provider1` through `provider2`

## Benchmark comparison

**Disclaimer:** Always benchmark yourself

Specs:
* Macbook Pro M1 Pro Monterey 12.4
* Dart SDK version: 2.17.6 (stable) on "macos_arm64"
  
I've run all benchmarks with `dart run`

**honeycomb**:
```
================ RESULTS ================
:::JSON::: {"create10_iteration":143.89000000000001,"create100_iteration":149.57,"create500_iteration":149.14000000000001,"create2000_iteration":148.97}
================ FORMATTED ==============
create10: 143.9 ns per iteration
create100: 149.6 ns per iteration
create500: 149.1 ns per iteration
create2000: 149.0 ns per iteration

================ RESULTS ================
:::JSON::: {"read1_iteration":36.42,"read10_iteration":29.240000000000002,"read50_iteration":29.060000000000002,"read500_iteration":29.48}
================ FORMATTED ==============
read1: 36.4 ns per iteration
read10: 29.2 ns per iteration
read50: 29.1 ns per iteration
read500: 29.5 ns per iteration

================ RESULTS ================
:::JSON::: {"create_scoped50":45088.270000000004,"create_scoped100":124254.7,"create_scoped200":274012.73}
================ FORMATTED ==============
create provider with scoped transitive dependency and depth == 50: 45088.3 ns per iteration
create provider with scoped transitive dependency and depth == 100: 124254.7 ns per iteration
create provider with scoped transitive dependency and depth == 200: 274012.7 ns per iteration
```
<br>

**riverpod**

```
================ RESULTS ================
:::JSON::: {"create10_iteration":153.81,"create100_iteration":155.49,"create500_iteration":156.42000000000002,"create2000_iteration":155.62}
================ FORMATTED ==============
create10: 153.8 ns per iteration
create100: 155.5 ns per iteration
create500: 156.4 ns per iteration
create2000: 155.6 ns per iteration

================ RESULTS ================
:::JSON::: {"read1_iteration":39.27,"read10_iteration":36.68,"read50_iteration":35.92,"read500_iteration":35.32}
================ FORMATTED ==============
read1: 39.3 ns per iteration
read10: 36.7 ns per iteration
read50: 35.9 ns per iteration
read500: 35.3 ns per iteration

================ RESULTS ================
:::JSON::: {"create_scoped50":52134.64,"create_scoped100":440524.76,"create_scoped200":2088768.51}
================ FORMATTED ==============
create provider with scoped transitive dependency and depth == 50: 52134.6 ns per iteration
create provider with scoped transitive dependency and depth == 100: 440524.8 ns per iteration
create provider with scoped transitive dependency and depth == 200: 2088768.5 ns per iteration
```

## Is it production ready?
Not enough testing have been done to consider this production ready.
But I'm going to use it on production project.

## Credits
The whole project inspired by [riverpod](https://github.com/rrousselGit/riverpod), created by [Remi Rousselet](https://github.com/rrousselGit) and community.