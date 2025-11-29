#!/bin/bash

# Download AI models for bundling with the app
# Run this ONCE during development to download models to assets/

set -e

MODELS_DIR="assets/models"
mkdir -p "$MODELS_DIR"

echo "🤖 Downloading AI models for EduMate Lite..."
echo ""

# Check for HuggingFace token
if [ -z "$HUGGINGFACE_TOKEN" ]; then
    echo "❌ Error: HUGGINGFACE_TOKEN environment variable not set"
    echo ""
    echo "Please set your token:"
    echo "  export HUGGINGFACE_TOKEN='hf_your_token_here'"
    echo ""
    echo "Get token from: https://huggingface.co/settings/tokens"
    echo "Request access to:"
    echo "  - https://huggingface.co/google/embeddinggemma-300m"
    echo "  - https://huggingface.co/google/gemma-3n-E2B-it-litert-preview"
    exit 1
fi

echo "✅ Token found"
echo ""
echo "📋 Model sources:"
echo "   - Embedding: litert-community/embeddinggemma-300m (PUBLIC - no auth)"
echo "   - Inference: google/gemma-3n-E2B-it-litert-preview (GATED)"
echo ""
echo "⚠️  IMPORTANT: Request access to Gemma 3 Nano E2B:"
echo "   Visit: https://huggingface.co/google/gemma-3n-E2B-it-litert-preview"
echo "   Click 'Request Access' button (while logged in)"
echo "   Approval is usually instant!"
echo ""
read -p "Press Enter to continue after requesting access..."
echo ""

# Download Embedding Model (from litert-community - public repo)
echo "📥 Downloading Embedding Model (~300MB)..."
curl -L \
  --progress-bar \
  -o "$MODELS_DIR/embeddinggemma-300M_seq512_mixed-precision.tflite" \
  "https://huggingface.co/litert-community/embeddinggemma-300m/resolve/main/embeddinggemma-300M_seq512_mixed-precision.tflite"

if [ $? -ne 0 ]; then
    echo "❌ Failed to download embedding model"
    echo "   This is a PUBLIC repo - should not need auth"
    exit 1
fi

# Verify file size (should be >100MB)
FILE_SIZE=$(stat -f%z "$MODELS_DIR/embeddinggemma-300M_seq512_mixed-precision.tflite" 2>/dev/null || stat -c%s "$MODELS_DIR/embeddinggemma-300M_seq512_mixed-precision.tflite" 2>/dev/null)
if [ "$FILE_SIZE" -lt 100000000 ]; then
    echo "❌ Downloaded file is too small ($FILE_SIZE bytes) - likely an error page"
    echo "   Check if you requested access at: https://huggingface.co/google/embeddinggemma-300m"
    cat "$MODELS_DIR/embeddinggemma-300M_seq512_mixed-precision.tflite"
    exit 1
fi

echo "✅ Embedding model downloaded ($(du -h "$MODELS_DIR/embeddinggemma-300M_seq512_mixed-precision.tflite" | cut -f1))"
echo ""

# Download Embedding Tokenizer (from litert-community - public repo)
echo "📥 Downloading Embedding Tokenizer (~5MB)..."
curl -L \
  --progress-bar \
  -o "$MODELS_DIR/sentencepiece.model" \
  "https://huggingface.co/litert-community/embeddinggemma-300m/resolve/main/sentencepiece.model"

if [ $? -ne 0 ]; then
    echo "❌ Failed to download tokenizer"
    exit 1
fi

# Verify file size (should be >1MB)
FILE_SIZE=$(stat -f%z "$MODELS_DIR/sentencepiece.model" 2>/dev/null || stat -c%s "$MODELS_DIR/sentencepiece.model" 2>/dev/null)
if [ "$FILE_SIZE" -lt 1000000 ]; then
    echo "❌ Downloaded file is too small ($FILE_SIZE bytes) - likely an error page"
    cat "$MODELS_DIR/sentencepiece.model"
    exit 1
fi

echo "✅ Tokenizer downloaded ($(du -h "$MODELS_DIR/sentencepiece.model" | cut -f1))"
echo ""

# Download Inference Model (requires auth token and access approval)
echo "📥 Downloading Gemma 3 Nano E2B (~3.5GB - this will take a while)..."
curl -L \
  --progress-bar \
  -H "Authorization: Bearer $HUGGINGFACE_TOKEN" \
  -o "$MODELS_DIR/gemma-3n-E2B-it-int4.task" \
  "https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task"

if [ $? -ne 0 ]; then
    echo "❌ Failed to download inference model"
    echo "   Check if you requested access at: https://huggingface.co/google/gemma-3n-E2B-it-litert-preview"
    exit 1
fi

# Verify file size (should be >3GB)
FILE_SIZE=$(stat -f%z "$MODELS_DIR/gemma-3n-E2B-it-int4.task" 2>/dev/null || stat -c%s "$MODELS_DIR/gemma-3n-E2B-it-int4.task" 2>/dev/null)
if [ "$FILE_SIZE" -lt 3000000000 ]; then
    echo "❌ Downloaded file is too small ($FILE_SIZE bytes) - likely an error page"
    echo "   Check if you requested access at: https://huggingface.co/google/gemma-3n-E2B-it-litert-preview"
    head -20 "$MODELS_DIR/gemma-3n-E2B-it-int4.task"
    exit 1
fi

echo "✅ Inference model downloaded ($(du -h "$MODELS_DIR/gemma-3n-E2B-it-int4.task" | cut -f1))"
echo ""

echo "🎉 All models downloaded successfully!"
echo ""
echo "Files in $MODELS_DIR:"
ls -lh "$MODELS_DIR"
echo ""
echo "Next steps:"
echo "1. Models are now in assets/models/"
echo "2. They will be bundled with the app"
echo "3. No token needed for users!"
echo "4. Build with: flutter build apk"

