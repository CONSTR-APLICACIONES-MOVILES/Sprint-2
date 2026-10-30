package com.example.parchapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import com.google.android.gms.maps.model.LatLng
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.AutocompleteSessionToken
import com.google.android.libraries.places.api.model.CircularBounds
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsRequest
import com.google.android.libraries.places.api.net.FetchPlaceRequest

class MainActivity : FlutterActivity() {
    private val sessions = mutableMapOf<String, AutocompleteSessionToken>()
    private fun mapsKey(): String = packageManager
        .getApplicationInfo(packageName, PackageManager.GET_META_DATA)
        .metaData?.getString("com.google.android.geo.API_KEY") ?: ""

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "parchapp/google_places")
            .setMethodCallHandler { call, result ->
                if (call.method == "isConfigured") {
                    result.success(mapsKey().isNotBlank())
                    return@setMethodCallHandler
                }
                val session = call.argument<String>("session") ?: ""
                if (call.method == "endSession") {
                    sessions.remove(session); result.success(null)
                    return@setMethodCallHandler
                }
                if (mapsKey().isBlank()) {
                    result.error("MAPS_NOT_CONFIGURED", "Maps are unavailable in this build.", null)
                    return@setMethodCallHandler
                }
                if (session.length !in 16..100) {
                    result.error("INVALID_ARGUMENT", "Invalid search session.", null)
                    return@setMethodCallHandler
                }
                if (!Places.isInitialized()) Places.initializeWithNewPlacesApiEnabled(applicationContext, mapsKey())
                if (sessions.size >= 20 && !sessions.containsKey(session)) sessions.clear()
                val token = sessions.getOrPut(session) { AutocompleteSessionToken.newInstance() }
                val client = Places.createClient(this)
                when (call.method) {
                    "search" -> {
                        val query = call.argument<String>("query")?.trim() ?: ""
                        if (query.length !in 3..200) {
                            result.success(emptyList<Map<String, String>>())
                            return@setMethodCallHandler
                        }
                        val latitude = call.argument<Double>("latitude") ?: 4.60971
                        val longitude = call.argument<Double>("longitude") ?: -74.08175
                        val request = FindAutocompletePredictionsRequest.builder().setQuery(query)
                            .setSessionToken(token).setCountries("CO")
                            .setLocationBias(CircularBounds.newInstance(LatLng(latitude, longitude), 30000.0)).build()
                        client.findAutocompletePredictions(request).addOnSuccessListener { response ->
                            result.success(response.autocompletePredictions.map { p -> mapOf(
                                "id" to p.placeId, "title" to p.getPrimaryText(null).toString(),
                                "address" to p.getSecondaryText(null).toString()) })
                        }.addOnFailureListener { result.error("PLACES_SEARCH_FAILED", "Unable to search places right now.", null) }
                    }
                    "details" -> {
                        val id = call.argument<String>("id") ?: ""
                        if (id.isBlank() || id.length > 300) {
                            result.error("INVALID_ARGUMENT", "Invalid place.", null)
                            return@setMethodCallHandler
                        }
                        val request = FetchPlaceRequest.builder(id,
                            listOf(Place.Field.ID, Place.Field.DISPLAY_NAME, Place.Field.FORMATTED_ADDRESS, Place.Field.LOCATION))
                            .setSessionToken(token).build()
                        client.fetchPlace(request).addOnSuccessListener { response ->
                            sessions.remove(session)
                            val p = response.place
                            val point = p.location
                            if (point == null) result.error("PLACE_NO_LOCATION", "The place has no map location.", null)
                            else {
                                val name = p.displayName ?: ""
                                val address = p.formattedAddress ?: ""
                                val label = if (address.contains(name, ignoreCase = true)) address else listOf(name, address).filter { it.isNotBlank() }.joinToString(" · ")
                                result.success(mapOf("latitude" to point.latitude, "longitude" to point.longitude,
                                    "label" to label.take(500), "placeId" to (p.id ?: id)))
                            }
                        }.addOnFailureListener { sessions.remove(session); result.error("PLACES_DETAILS_FAILED", "Unable to load this place.", null) }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
