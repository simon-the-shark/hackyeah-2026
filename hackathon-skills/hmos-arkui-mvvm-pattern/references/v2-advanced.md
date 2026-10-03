# V2 Global State: AppStorageV2 / PersistenceV2

## API Signature

The first argument to `connect` is the **class itself**, not `this`:

```typescript
// ✓ Correct
@Local appState: AppState = AppStorageV2.connect(AppState, 'appState', () => new AppState())!;
@Local prefs: UserPreferences = PersistenceV2.connect(UserPreferences, 'userPrefs', () => new UserPreferences())!;
```

All `connect` calls using the same key share one instance. If it does not exist on the first `connect`, the factory function in the third argument creates the default instance.

## Usage Example

```typescript
// viewmodel/AppState.ets — define the global state class
@ObservedV2
export class AppState {
  @Trace theme: string = 'light';
  @Trace isLoggedIn: boolean = false;
}

// pages/SettingsPage.ets — Page A modifies the state
@ComponentV2
struct SettingsPage {
  @Local appState: AppState = AppStorageV2.connect(AppState, 'appState', () => new AppState())!;

  build() {
    Toggle({ isOn: this.appState.theme === 'dark' })
      .onChange((isOn: boolean) => {
        this.appState.theme = isOn ? 'dark' : 'light';
      })
  }
}

// pages/HomePage.ets — Page B reads the same state
@ComponentV2
struct HomePage {
  @Local appState: AppState = AppStorageV2.connect(AppState, 'appState', () => new AppState())!;

  build() {
    Text(`Current theme: ${this.appState.theme}`)
  }
}
```

## Choosing AppStorageV2 vs PersistenceV2

| Scenario | Choice | Reason |
|------|------|------|
| Login state | AppStorageV2 | The user should log in again after the app closes |
| Theme preference | PersistenceV2 | The user wants the choice retained after restart |
| Temporary cache | AppStorageV2 | Persistence is not needed |
| User settings | PersistenceV2 | Settings should persist across sessions |
