package io.flutter.embedding_gemma

import android.content.Context
import android.os.Build
import android.util.Log
import com.google.ai.edge.localagents.rag.models.EmbedData
import com.google.ai.edge.localagents.rag.models.EmbeddingRequest
import com.google.ai.edge.localagents.rag.models.GemmaEmbeddingModel
import com.google.common.collect.ImmutableList
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.runBlocking
import java.io.File

/**
 * Google RAG library-based embedding engine for EmbeddingGemma-300M
 */
class EmbeddingEngine(
    private val context: Context,
    private val modelPath: String,
    private val tokenizerPath: String,
    private val dimensions: Int,
    private val requestedBackend: EmbeddingBackend
) {
    private var gemmaEmbeddingModel: GemmaEmbeddingModel? = null
    private var actualBackend: EmbeddingBackend = EmbeddingBackend.CPU
    
    companion object {
        private const val TAG = "EmbeddingEngine"
    }
    
    fun getActualBackend(): EmbeddingBackend = actualBackend
    
    fun initialize() {
        // Verify files exist
        val modelFile = File(modelPath)
        if (!modelFile.exists()) {
            throw IllegalArgumentException("Model file not found: $modelPath")
        }

        val tokenizerFile = File(tokenizerPath)
        if (!tokenizerFile.exists()) {
            throw IllegalArgumentException("Tokenizer file not found: $tokenizerPath")
        }

        // Smart GPU detection
        val requestedGpu = when (requestedBackend) {
            EmbeddingBackend.GPU, EmbeddingBackend.GPU_FLOAT16, 
            EmbeddingBackend.GPU_MIXED -> true
            EmbeddingBackend.CPU -> false
        }

        val useGpu = requestedGpu && GpuCapabilityChecker.canUseGpu(context)
        actualBackend = if (useGpu) requestedBackend else EmbeddingBackend.CPU

        // Initialize
        gemmaEmbeddingModel = GemmaEmbeddingModel(modelPath, tokenizerPath, useGpu)
        Log.i(TAG, "Initialized with ${actualBackend} backend")
    }
    
    private fun isEmulator(): Boolean {
        return Build.FINGERPRINT.startsWith("generic")
            || Build.MODEL.contains("Emulator")
            || Build.MODEL.contains("Android SDK built for x86")
            || Build.PRODUCT.contains("sdk")
    }
    
    fun embed(text: String, isQuery: Boolean): List<Double> {
        val model = gemmaEmbeddingModel 
            ?: throw IllegalStateException("Engine not initialized")
        
        // Apply task-specific prompt per Google's EmbeddingGemma spec
        val promptedText = if (isQuery) {
            "task: search result | query: $text"
        } else {
            "title: none | text: $text"
        }
        
        try {
            val embedData = EmbedData.builder<String>()
                .setData(promptedText)
                .setTask(EmbedData.TaskType.SEMANTIC_SIMILARITY)
                .build()

            val request = EmbeddingRequest.create(ImmutableList.of(embedData))

            return runBlocking {
                model.getEmbeddings(request).await().map { it.toDouble() }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Embedding failed: ${e.message}")
            throw RuntimeException("Failed to generate embedding", e)
        }
    }
    
    fun embedBatch(texts: List<String>, isQuery: Boolean): List<List<Double>> {
        return texts.map { text -> embed(text, isQuery) }
    }
    
    /**
     * Count tokens for text (approximate)
     * 
     * Note: GemmaEmbeddingModel doesn't expose tokenizer directly.
     * This uses character-based estimation: ~4 chars per token for English.
     * Add 10 tokens for task prompt overhead.
     */
    fun countTokens(text: String, withPrompt: Boolean): Int {
        val baseText = if (withPrompt) {
            // Add task prompt overhead
            "title: none | text: $text"
        } else {
            text
        }
        
        // Approximate token count (English: ~4 chars per token)
        // SentencePiece typically produces 0.7-0.8 tokens per word
        val words = baseText.split(Regex("\\s+")).size
        val chars = baseText.length
        
        // Use word-based for short text, char-based for long text
        val estimate = if (words < 100) {
            (words * 0.75).toInt() // 0.75 tokens per word
        } else {
            (chars / 4.0).toInt() // 4 chars per token
        }
        
        // Add special tokens (BOS, EOS)
        return estimate + 2
    }
    
    fun dispose() {
        gemmaEmbeddingModel = null
    }
}
