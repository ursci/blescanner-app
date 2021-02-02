# BLE Scanner mobile app

Mobile app of the "BLE Scanner" project.

## Getting Started

This project is a Flutter application. For help with Flutter, view the [online documentation](https://flutter.dev/docs), which offers tutorials, samples, guidance on mobile development, and a full API reference.

## Requirements

This mobile app requires [BLE Scanner Server](https://github.com/ursci/blescanner-server).

BLE-Scanner Application.

```
>>>>>>> 527618e44ac0eb8f94d62958e6c028943773b152
```

## Build for Android

```
flutter clean
flutter channel stable
flutter pub get
flutter build appbundle --release
```

Note: Use the `ftr/release` branch for specific settings to create a signed app bundle, which requires a keystore and settings configured in `android/key.properties` as

```
storePassword=mypassword
keyPassword=mypassword
keyAlias=mykey
storeFile=/path/to/key.jks
```

## Build for iOS

```
flutter clean
flutter channel stable
flutter pub get
flutter build ios
```

After above:
1. Open `ios/Runner.xcworkspace` by Xcode >= 12.x
2. Select [Product] / [Archive] menu
3. Click [Validate App] button
4. Click [Distribute App] button

## License

This program is free software. See [LICENSE](LICENSE) for more information.
