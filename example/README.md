# Flutter In-App Purchase Example

Example app demonstrating the usage of `flutter_inapp_purchase` plugin.

## Quick Start

```bash
# Run on any device (uses Google Play Billing by default)
flutter run

# Build release APK
flutter build apk --release
```

## Building with Different Billing Platforms

This example supports multiple billing platforms:

- **Google Play Billing** (default)
- **Meta Horizon Billing** (for Meta Quest devices)

### Google Play (Default)

No configuration needed! Just build and run:

```bash
flutter run
flutter build apk --release
```

### Meta Horizon (Meta Quest)

To use Meta Horizon billing:

1. **Enable Horizon** in `android/gradle.properties`:
   ```properties
   horizonEnabled=true
   ```

2. **Add Horizon App ID** to `android/local.properties`:
   ```properties
   HORIZON_APP_ID=your_horizon_app_id_here
   ```

3. **Run on Quest**:
   ```bash
   flutter run -d Quest
   flutter build apk --release
   ```

**No flavor specification needed!** The build system automatically selects the correct billing platform based on `horizonEnabled`.

## IDE Configuration

### Android Studio

Just click **Run** - the build system automatically selects the right platform based on `horizonEnabled` in `gradle.properties`.

### VS Code

Press F5 or click **Start Debugging** - works out of the box!

## Testing

- **Google Play**: Test on any Android device with Google Play Store (default)
- **Meta Horizon**: Set `horizonEnabled=true` and test on Meta Quest devices
