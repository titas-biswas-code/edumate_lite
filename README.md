# EduMate Lite

On-device AI-powered educational assistant for grades 5-10 students.

## Features

- 📚 Import study materials (PDF, images, camera)
- 🤖 Ask questions with AI (RAG-based)
- 📝 Practice quizzes generation
- 🔒 **Privacy-first** (all processing on-device)
- ✈️ **100% Offline** (models bundled with app)
- 🔐 **No token exposure** (secure bundled approach)

## Quick Start

### For Users (Production Build)

```bash
# Just run - models are bundled, no setup needed!
flutter run
```

App will load bundled AI models on first launch (~30 seconds).

### For Developers (First Time Setup)

Models are bundled with the app, so you need to download them once:

```bash
# 1. Get HuggingFace token (one-time, for downloading models to bundle)
#    Visit: https://huggingface.co/settings/tokens
#    Request access to:
#      - https://huggingface.co/google/embeddinggemma-300m  
#      - https://huggingface.co/google/gemma-3n-E2B-it-litert-preview

# 2. Download models to assets/ (ONE TIME ONLY)
export HUGGINGFACE_TOKEN='hf_your_token_here'
./scripts/download_models.sh

# 3. Run app (models now bundled)
flutter run
```

**Note:** After initial download, models are in `assets/models/` and will be bundled with all future builds. You don't need the token again.

## Architecture

**Bundled Model Approach (Secure & Private):**
- ✅ Models packaged in app bundle (~4GB total app size)
- ✅ No HuggingFace token in production app
- ✅ No token exposure risk
- ✅ Works 100% offline from first launch
- ✅ No per-user download costs
- ✅ Perfect for COPPA compliance (kids app)
- ✅ Aligns with "privacy-first" value proposition

**Flow:**
```
User installs app (4GB from Play Store)
  → Tap "Load Models"  
  → Models load from bundled assets (30 sec)
  → Ready to use offline forever
  → No internet, no tokens, no external calls
```

## Project Structure

```
lib/
├── config/              # DI setup (GetIt)
├── core/                # Constants, errors, utils
├── domain/              # Entities, interfaces, services
├── infrastructure/      # Database, AI, input adapters
├── stores/              # MobX state management
└── presentation/        # UI screens & widgets

assets/models/           # Bundled AI models (downloaded once)
├── embeddinggemma-300M_seq512_mixed-precision.tflite
├── embeddinggemma_tokenizer.model
└── gemma-3n-E2B-it-int4.task
```

## Technologies

- **State:** MobX 2.5.0 + flutter_mobx 2.3.0
- **DI:** GetIt 8.0.3
- **Database:** ObjectBox 4.3.0 (HNSW vector search)
- **AI:** flutter_gemma 0.11.13
- **PDF:** Syncfusion 27.2.5
- **Theme:** FlexColorScheme 8.3.1
- **Error Handling:** Dartz 0.10.1

## Testing

```bash
# Run all tests (40 tests)
flutter test

# Run specific test
flutter test test/domain/services/rag_engine_test.dart

# Analyze code
flutter analyze
```

**Current: 40 tests passing, 0 errors**

## Building for Production

```bash
# Android (APK will be ~4GB)
flutter build apk --release

# iOS
flutter build ios --release

# App Bundle (recommended for Play Store - uses on-demand delivery)
flutter build appbundle --release
```

**Note:** App size is ~4GB due to bundled models. This is acceptable for educational apps with significant offline value.

## Requirements

- **Storage:** 4.5GB (4GB models + 500MB app/data)
- **RAM:** 6GB+ device RAM recommended
- **Android:** API 21+ (tested on 15+)
- **iOS:** 16.0+ (MediaPipe requirement)

## Security & Privacy

✅ **No Token Exposure:**
- Models are pre-downloaded by developer
- Bundled in app assets
- No tokens in production builds
- Users never need HuggingFace access

✅ **100% On-Device:**
- All AI processing happens locally
- No data leaves the device
- No API calls after model loading
- COPPA compliant

✅ **Open Source:**
- Full source code available
- Auditable security
- No hidden backend calls

## Why Bundled Models?

| Aspect | Bundled (Current) | Download on Install |
|--------|-------------------|---------------------|
| **Security** | ✅ No token exposure | ❌ Token in app = risk |
| **Privacy** | ✅ Offline from install | ⚠️ Initial internet needed |
| **UX** | ✅ Load in 30 sec | ⚠️ Download 4GB (30+ min) |
| **Distribution** | ✅ One-time download | ✅ Smaller initial |
| **COPPA** | ✅ Perfect for kids | ⚠️ Network calls |
| **Cost** | ✅ One-time dev download | ⚠️ Per-user bandwidth |

For a **privacy-first kids educational app**, bundled is the right choice.

## Development Notes

- Models in `assets/models/` are gitignored (too large for git)
- Download script provided for developers
- After first download, commit pubspec.yaml changes
- Future developers can download models with same script

## License

MIT License - See LICENSE file
