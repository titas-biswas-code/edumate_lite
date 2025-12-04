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
    private var tokenizer: SentencePieceTokenizer? = null
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

        // Initialize embedding model
        gemmaEmbeddingModel = GemmaEmbeddingModel(modelPath, tokenizerPath, useGpu)
        
        // Initialize tokenizer for counting
        try {
            tokenizer = SentencePieceTokenizer(tokenizerPath)
            Log.i(TAG, "Initialized with ${actualBackend} backend + tokenizer")
        } catch (e: Exception) {
            Log.w(TAG, "Tokenizer init failed (countTokens will use approximation): ${e.message}")
            Log.i(TAG, "Initialized with ${actualBackend} backend")
        }
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
     * Count ACTUAL tokens using SentencePiece tokenizer
     */
    fun countTokens(text: String, withPrompt: Boolean): Int {
        val baseText = if (withPrompt) {
            "title: none | text: $text"
        } else {
            text
        }
        
        return if (tokenizer != null) {
            try {
                tokenizer!!.countTokens(baseText)
            } catch (e: Exception) {
                Log.w(TAG, "Tokenizer failed, using approximation: ${e.message}")
                approximateTokenCount(baseText)
            }
        } else {
            approximateTokenCount(baseText)
        }
    }
    
    /**
     * Fallback approximation if tokenizer fails
     */
    private fun approximateTokenCount(text: String): Int {
        if (text.isEmpty()) return 2
        return (text.length / 3.3).toInt() + 2
    }
    
    fun dispose() {
        gemmaEmbeddingModel = null
        tokenizer = null
    }
}
