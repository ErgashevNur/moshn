package uz.moshn.moshn

import com.yandex.mapkit.MapKitFactory
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("1f1dbc7c-8a01-46da-9e77-b9c2572d89d9")
    }
}
