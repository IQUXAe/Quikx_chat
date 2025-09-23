package com.iquxae.quikxchat

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

import android.content.Context

class MainActivity : FlutterActivity() {


    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return provideEngine(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(BatteryOptimizationPlugin())
    }

    companion object {
        private var engine: FlutterEngine? = null
        
        @Synchronized
        fun provideEngine(context: Context): FlutterEngine {
            val eng = engine ?: FlutterEngine(context, emptyArray(), true, false)
            engine = eng
            return eng
        }
        
        @Synchronized
        fun cleanupEngine() {
            engine?.destroy()
            engine = null
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        if (isFinishing) {
            cleanupEngine()
        }
    }
}
