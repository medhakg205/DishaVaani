# DishaVaani

DishaVaani is a Flutter audio guide that matches nearby points of interest to
the user's location and heading.

## Project structure

```text
lib/
	main.dart                         Flutter/Firebase entry point
	app.dart                          MaterialApp and global theme
	core/
		config/                         Generated platform configuration
		constants/                      Shared application constants
		logic/                          Pure application logic
		settings/                       User-facing settings
	models/                           Firestore and domain data models
	screens/                          All application screens
	services/                         Firebase, sensors, audio, network, and matching
	widgets/                          Reusable UI components
functions/                          Firebase Functions and local backend tools
test/                               Flutter widget and unit tests
```

Screens belong in `lib/screens`, domain models in `lib/models`, and runtime
integrations in `lib/services`. The matching engine in
`lib/services/matching_engine.dart` is the single canonical implementation.

## Development

```text
flutter pub get
flutter analyze
flutter test
```

Firebase options are generated at `lib/core/config/firebase_options.dart`; keep
that path in sync with `firebase.json` when regenerating configuration.
