package com.color.paletteasian

import io.flutter.embedding.android.FlutterFragmentActivity
import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import android.webkit.WebView

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        
        // Initialize WebView with the correct context
        try {
            WebView.setWebContentsDebuggingEnabled(false)
            val webView = WebView(this)
            webView.destroy()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}