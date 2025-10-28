# Flutter In-App Purchase Example

Example app demonstrating the usage of `flutter_inapp_purchase` plugin.

## Building with Flavors

This example supports multiple product flavors for different billing platforms:

- **horizon**: Meta Horizon Billing (default - for Meta Quest devices)
- **play**: Google Play Billing

### Command Line

```bash
# Play flavor (Google Play Billing)
flutter run --flavor play

# Horizon flavor (Meta Horizon Billing)
flutter run --flavor horizon

# Build APK
flutter build apk --flavor play
flutter build apk --flavor horizon
```

### Android Studio / IntelliJ IDEA

1. Open the project in Android Studio
2. Select the run configuration from the dropdown:
   - `example (play)` - Run with Google Play Billing
   - `example (horizon)` - Run with Meta Horizon Billing
3. Click Run

The run configurations are located in `.idea/runConfigurations/`.

### VS Code

The default flavor is set to **horizon** (Meta Quest). You can:

#### Option 1: Use default (Quick Start)

1. Press F5 or click **Start Debugging**
2. The app will run with horizon flavor by default

#### Option 2: Select specific flavor

1. Go to **Run and Debug** (Cmd/Ctrl + Shift + D)
2. Select a configuration from the dropdown:
   - `example (horizon) - Meta Quest` - Debug with Meta Horizon Billing (default)
   - `example (play) - Google Play` - Debug with Google Play Billing
   - Profile and Release variants are also available
3. Press F5 or click **Start Debugging**

**Configuration files:**
- Default flavor: `.vscode/settings.json`
- Launch configurations: `.vscode/launch.json`

### Gradle (Android only)

```bash
cd android

# Debug builds
./gradlew assemblePlayDebug
./gradlew assembleHorizonDebug

# Release builds
./gradlew assemblePlayRelease
./gradlew assembleHorizonRelease
```

## Configuration

### Horizon App ID

For the Horizon flavor, you need to configure your Meta Horizon App ID:

1. Create `android/local.properties` (if it doesn't exist)
2. Add your Horizon App ID:

```properties
EXAMPLE_HORIZON_APP_ID=your_horizon_app_id_here
```

This ensures the Horizon billing client can connect properly on Meta Quest devices.

## Testing

- Use **Play flavor** for testing on regular Android devices with Google Play Store
- Use **Horizon flavor** for testing on Meta Quest devices with Meta Horizon Store
