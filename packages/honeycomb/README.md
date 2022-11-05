Service Locator for Dart and Flutter

### Navigation
- [How is it different from Riverpod?](#how-is-it-different-from-riverpod)
- [How is it different from GetIt?](#how-is-it-different-from-getit)
- [Getting started](#getting-started)
- [Features](#features)
  - [Providers](#providers)
    - [Injecting providers](#injecting-providers)
    - [Disposing providers](#disposing-providers)
  - [Overrides](#overrides)
    - [Example](#example)
  - [Scopes](#scopes)
    - [Dependencies*](#dependencies)
- [Is it production ready?](#is-it-production-ready)
- [Credits](#credits)

## How is it different from Riverpod?
* It's not a state management solution
* Only 2 provider types
* No need to specify `dependencies` to achieve correct scoping

## How is it different from GetIt?
* Type-safe factories (no more param1 and param2)
* Providers are registered at compile-time
* Ability to register the same type twice or more in type-safe manner.
  
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
final containerChild = ProviderContainer(
    overrides: [userProvider.scope()],
    parent: containerRoot,
);

void main() {
    final rootUser = containerRoot.read(userProvider);
    final childUser = containerChild.read(userProvider);

    identical(rootUser, childUser); // false
}
```
`provider.scope()` is essentially the same as `provider.overrideWith(provider)`, so scoping and overriding are basically the same thing.

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

## Is it production ready?
Not enough testing have been done to consider this production ready.
But I'm going to use it on production project.

## Credits
The whole project inspired by [riverpod](https://github.com/rrousselGit/riverpod), created by [Remi Rousselet](https://github.com/rrousselGit) and community.