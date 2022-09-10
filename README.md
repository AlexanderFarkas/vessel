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

Smart IoC-container

*Disclaimer: `honeycomb` is not a state management solution. It's a tool for Dependency Injection* 

### Navigation
- [Getting started](#getting-started)
- [Features](#features)
  - [Providers](#providers)
    - [Injecting providers](#injecting-providers)
    - [Disposing providers](#disposing-providers)
  - [Overrides](#overrides)
    - [Example](#example)
  - [Scopes](#scopes)
    - [Dependencies*](#dependencies)

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
final container = Container();
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
final userVmProvider = ProviderFactory(
    (_, int userId) => UserViewModel(userId),
);
```

The difference between these two is that `ProviderFactory` creates providers, while usual providers are self-contained.

Consider `Provider` usage:
```dart
container.read(counterProvider) // Counter instance
```

And `ProviderFactory`:
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

final cartViewModelProvider = ProviderFactory((read, int cartId) {
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
    final container = Container(
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

final userProfileVmProvider = ProviderFactory(
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

final containerWithOverride = Container(
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
final containerRoot = Container();
final containerChild = Container(
    parent: containerRoot, 
    overrides: [userProvider],
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


final container = Container();
final containerChild = Container(
    parent: container, 
    overrides: [provider2],
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
