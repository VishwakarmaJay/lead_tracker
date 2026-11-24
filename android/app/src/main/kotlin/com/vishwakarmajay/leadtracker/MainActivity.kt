package com.vishwakarmajay.leadtracker

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ShareBridge(applicationContext).attach(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Cold start. Skip intents Android re-delivers: an activity recreated
        // from saved state, or a relaunch from Recents, carries the same share
        // that was already handled.
        val launchedFromHistory =
            intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0
        if (savedInstanceState == null && !launchedFromHistory) {
            ShareIntake.handle(applicationContext, intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        // Warm start: the app is already running (launchMode singleTop).
        super.onNewIntent(intent)
        setIntent(intent)
        ShareIntake.handle(applicationContext, intent)
    }
}
