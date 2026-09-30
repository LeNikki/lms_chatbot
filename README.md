# lms_chatbot

A new Flutter project.

## Golden Tests

Golden tests are already setup for this project. To run the tests and update the golden files, run:

```bash
flutter test --update-goldens
```

The golden test screenshots will be stored under `test/golden/`.

## Setup

The Gemini API key is **not** committed. It lives in `env.json`, which is gitignored.

```bash
cp env.example.json env.json
# then edit env.json and paste your key into the "API_KEY" field
```

`env.json` is a required asset, so **`flutter build` fails if the file is missing**. Make sure it exists before building.

Alternatively, override the key at run time without touching `env.json`:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

`--dart-define` takes precedence over `env.json` when both are present.

### Note on the API key

Because the Gemini call is made directly from the app, the key is bundled into the built
APK/IPA and can be extracted by anyone with the binary. This is inherent to a client-side
Gemini call. The real mitigation is to restrict the key in Google AI Studio (limit it to the
Generative Language API, and to your package name / signing certificate).
# lms_chatbot
