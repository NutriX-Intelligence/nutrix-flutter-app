# flutter_local_notifications uses Gson internally (to persist scheduled
# notification details across reboots). R8 strips generic signatures by
# default, which breaks Gson's TypeToken-based deserialization at runtime
# ("TypeToken must be created with a type argument"). Keep what Gson needs.
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.dexterous.** { *; }
