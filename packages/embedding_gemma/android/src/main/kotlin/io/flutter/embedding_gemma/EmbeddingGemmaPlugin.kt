package io.flutter.embedding_gemma

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.*

/**
 * EmbeddingGemmaPlugin - Flutter plugin for on-device EmbeddingGemma-300M embeddings
 */
class EmbeddingGemmaPlugin: FlutterPlugin, EmbeddingGemmaApi {
    private var context: Context? = null
    private var embeddingEngine: EmbeddingEngine? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    
    companion object {
        private const val TAG = "EmbeddingGemmaPlugin"
    }
    
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        EmbeddingGemmaApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        EmbeddingGemmaApi.setUp(binding.binaryMessenger, null)
        context = null
        coroutineScope.cancel()
    }
    
    override fun initialize(request: InitializeRequest, callback: (Result<InitializeResponse>) -> Unit) {
        coroutineScope.launch {
            try {
                val ctx = context ?: throw IllegalStateException("Context not available")
                
                val engine = EmbeddingEngine(
                    context = ctx,
                    modelPath = request.modelPath,
                    tokenizerPath = request.tokenizerPath,
                    dimensions = request.dimensions.toInt(),
                    requestedBackend = request.backend
                )
                
                engine.initialize()
                embeddingEngine = engine
                
                val response = InitializeResponse(actualBackend = engine.getActualBackend())
                
                withContext(Dispatchers.Main) {
                    callback(Result.success(response))
                }
                
                Log.i(TAG, "Initialized (${engine.getActualBackend()} backend)")
            } catch (e: Exception) {
                Log.e(TAG, "Init failed: ${e.message}")
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }
    
    override fun embed(request: EmbedRequest, callback: (Result<EmbeddingResult>) -> Unit) {
        coroutineScope.launch {
            try {
                val engine = embeddingEngine 
                    ?: throw IllegalStateException("Engine not initialized")
                    
                val embedding = engine.embed(request.text, request.isQuery)
                val result = EmbeddingResult(embedding)
                
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Embed failed: ${e.message}")
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }
    
    override fun embedBatch(request: EmbedBatchRequest, callback: (Result<BatchEmbeddingResult>) -> Unit) {
        coroutineScope.launch {
            try {
                val engine = embeddingEngine 
                    ?: throw IllegalStateException("Engine not initialized")
                    
                val embeddings = engine.embedBatch(request.texts, request.isQuery)
                val result = BatchEmbeddingResult(embeddings)
                
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Batch failed: ${e.message}")
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }
    
    override fun countTokens(request: TokenCountRequest, callback: (Result<TokenCountResult>) -> Unit) {
        coroutineScope.launch {
            try {
                val engine = embeddingEngine 
                    ?: throw IllegalStateException("Engine not initialized")
                    
                val count = engine.countTokens(request.text, request.withPrompt)
                val result = TokenCountResult(count.toLong())
                
                withContext(Dispatchers.Main) {
                    callback(Result.success(result))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Token count failed: ${e.message}")
                withContext(Dispatchers.Main) {
                    callback(Result.failure(e))
                }
            }
        }
    }

    override fun dispose() {
        embeddingEngine?.dispose()
        embeddingEngine = null
    }
}
