# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.shell.** { *; }

# Flutter deferred components (specific rules for Play Store split install)
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager$* { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# Ensure Play Core classes are not obfuscated/removed
-dontwarn com.google.android.play.core.**
-keep,allowobfuscation,allowshrinking interface com.google.android.play.core.splitcompat.SplitCompatApplication
-keep,allowobfuscation,allowshrinking class * implements com.google.android.play.core.splitcompat.SplitCompatApplication

# WebView related rules
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.in_app_browser.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.chrome_custom_tabs.** { *; }
-keep class * extends android.webkit.WebChromeClient { *; }
-keep class * extends android.webkit.WebViewClient { *; }

# Keep WebView JavaScript interfaces
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Application specific rules
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }
-keep class com.vertex.solar.MainActivity { *; }
-keep class com.vertex.solar.BuildConfig { *; }

# UI Components and Widgets
-keep class **.widget.** { *; }
-keep class **.ui.** { *; }
-keep class **.screen.** { *; }
-keep class **.page.** { *; }
-keep class **.view.** { *; }
-keep class **.animation.** { *; }
-keep class **.style.** { *; }
-keep class **.theme.** { *; }
-keep class **.design.** { *; }

# Keep all classes that might be used in XML layouts
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep custom views and their properties
-keepclassmembers class * extends android.view.View {
    *** get*();
    void set*(***);
}

# Keep layout inflation
-keepclassmembers class * extends android.view.LayoutInflater { *; }

# Keep gesture detectors and touch handlers
-keep class * extends android.view.GestureDetector { *; }
-keep class * extends android.view.ScaleGestureDetector { *; }
-keep class * extends android.view.VelocityTracker { *; }

# Keep animations and transitions
-keep class * extends android.animation.Animator { *; }
-keep class * extends android.animation.AnimatorListenerAdapter { *; }
-keep class * extends android.transition.Transition { *; }
-keep class android.animation.** { *; }
-keep class android.view.animation.** { *; }

# Keep graphics and drawables
-keep class android.graphics.** { *; }
-keep class * extends android.graphics.drawable.Drawable { *; }

# Keep accessibility support
-keep class * extends android.view.accessibility.AccessibilityNodeInfo { *; }
-keep class * extends android.view.accessibility.AccessibilityEvent { *; }

# Keep view state management
-keepclassmembers class * extends android.view.View {
    android.view.View$SavedState *;
    android.os.Parcelable onSaveInstanceState();
    void onRestoreInstanceState(android.os.Parcelable);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R8 from optimizing certain classes
-dontobfuscate
-dontoptimize
-dontshrink

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Fix R8 missing classes - Keep annotation processing classes
-keep class javax.lang.model.** { *; }
-keep class javax.lang.model.element.** { *; }
-keep class javax.lang.model.element.Modifier { *; }

# Fix R8 missing classes - Keep XML processing classes (Apache Tika)
-keep class javax.xml.stream.** { *; }
-keep class javax.xml.stream.XMLStreamException { *; }

# Additional rules for annotation processing libraries commonly used by Flutter plugins
-keep class com.google.errorprone.** { *; }
-dontwarn com.google.errorprone.**

# Keep Apache Tika classes if used by any plugins
-keep class org.apache.tika.** { *; }
-dontwarn org.apache.tika.**

# Suppress warnings for missing optional dependencies
-dontwarn javax.lang.model.element.Modifier
-dontwarn javax.xml.stream.XMLStreamException

# Keep the BuildConfig
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep all dependencies
-keep class androidx.** { *; }
-keep class com.google.android.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Kotlin specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep `Companion` object fields of serializable classes
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects of serializable classes
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.shell.** { *; }

# WebView related rules
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.in_app_browser.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.chrome_custom_tabs.** { *; }
-keep class * extends android.webkit.WebChromeClient { *; }
-keep class * extends android.webkit.WebViewClient { *; }

# Keep WebView JavaScript interfaces
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Application specific rules
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }
-keep class com.vertex.solar.MainActivity { *; }
-keep class com.vertex.solar.BuildConfig { *; }

# UI Components and Widgets
-keep class **.widget.** { *; }
-keep class **.ui.** { *; }
-keep class **.screen.** { *; }
-keep class **.page.** { *; }
-keep class **.view.** { *; }
-keep class **.animation.** { *; }
-keep class **.style.** { *; }
-keep class **.theme.** { *; }
-keep class **.design.** { *; }

# Keep all classes that might be used in XML layouts
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep custom views and their properties
-keepclassmembers class * extends android.view.View {
    *** get*();
    void set*(***);
}

# Keep layout inflation
-keepclassmembers class * extends android.view.LayoutInflater { *; }

# Keep gesture detectors and touch handlers
-keep class * extends android.view.GestureDetector { *; }
-keep class * extends android.view.ScaleGestureDetector { *; }
-keep class * extends android.view.VelocityTracker { *; }

# Keep animations and transitions
-keep class * extends android.animation.Animator { *; }
-keep class * extends android.animation.AnimatorListenerAdapter { *; }
-keep class * extends android.transition.Transition { *; }
-keep class android.animation.** { *; }
-keep class android.view.animation.** { *; }

# Keep graphics and drawables
-keep class android.graphics.** { *; }
-keep class * extends android.graphics.drawable.Drawable { *; }

# Keep accessibility support
-keep class * extends android.view.accessibility.AccessibilityNodeInfo { *; }
-keep class * extends android.view.accessibility.AccessibilityEvent { *; }

# Keep view state management
-keepclassmembers class * extends android.view.View {
    android.view.View$SavedState *;
    android.os.Parcelable onSaveInstanceState();
    void onRestoreInstanceState(android.os.Parcelable);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R8 from optimizing certain classes
-dontobfuscate
-dontoptimize
-dontshrink

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep the BuildConfig
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep all dependencies
-keep class androidx.** { *; }
-keep class com.google.android.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Kotlin specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep `Companion` object fields of serializable classes
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects of serializable classes
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.shell.** { *; }

# WebView related rules
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.in_app_browser.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.chrome_custom_tabs.** { *; }
-keep class * extends android.webkit.WebChromeClient { *; }
-keep class * extends android.webkit.WebViewClient { *; }

# Keep WebView JavaScript interfaces
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Application specific rules
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }
-keep class com.vertex.solar.MainActivity { *; }
-keep class com.vertex.solar.BuildConfig { *; }

# UI Components and Widgets
-keep class **.widget.** { *; }
-keep class **.ui.** { *; }
-keep class **.screen.** { *; }
-keep class **.page.** { *; }
-keep class **.view.** { *; }
-keep class **.animation.** { *; }
-keep class **.style.** { *; }
-keep class **.theme.** { *; }
-keep class **.design.** { *; }

# Keep all classes that might be used in XML layouts
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep custom views and their properties
-keepclassmembers class * extends android.view.View {
    *** get*();
    void set*(***);
}

# Keep layout inflation
-keepclassmembers class * extends android.view.LayoutInflater { *; }

# Keep gesture detectors and touch handlers
-keep class * extends android.view.GestureDetector { *; }
-keep class * extends android.view.ScaleGestureDetector { *; }
-keep class * extends android.view.VelocityTracker { *; }

# Keep animations and transitions
-keep class * extends android.animation.Animator { *; }
-keep class * extends android.animation.AnimatorListenerAdapter { *; }
-keep class * extends android.transition.Transition { *; }
-keep class android.animation.** { *; }
-keep class android.view.animation.** { *; }

# Keep graphics and drawables
-keep class android.graphics.** { *; }
-keep class * extends android.graphics.drawable.Drawable { *; }

# Keep accessibility support
-keep class * extends android.view.accessibility.AccessibilityNodeInfo { *; }
-keep class * extends android.view.accessibility.AccessibilityEvent { *; }

# Keep view state management
-keepclassmembers class * extends android.view.View {
    android.view.View$SavedState *;
    android.os.Parcelable onSaveInstanceState();
    void onRestoreInstanceState(android.os.Parcelable);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R8 from optimizing certain classes
-dontobfuscate
-dontoptimize
-dontshrink

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep the BuildConfig
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep all dependencies
-keep class androidx.** { *; }
-keep class com.google.android.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Kotlin specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep `Companion` object fields of serializable classes
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects of serializable classes
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.shell.** { *; }

# WebView related rules
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.in_app_browser.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.chrome_custom_tabs.** { *; }
-keep class * extends android.webkit.WebChromeClient { *; }
-keep class * extends android.webkit.WebViewClient { *; }

# Keep WebView JavaScript interfaces
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Application specific rules
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }
-keep class com.vertex.solar.MainActivity { *; }
-keep class com.vertex.solar.BuildConfig { *; }

# UI Components and Widgets
-keep class **.widget.** { *; }
-keep class **.ui.** { *; }
-keep class **.screen.** { *; }
-keep class **.page.** { *; }
-keep class **.view.** { *; }
-keep class **.animation.** { *; }
-keep class **.style.** { *; }
-keep class **.theme.** { *; }
-keep class **.design.** { *; }

# Keep all classes that might be used in XML layouts
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep custom views and their properties
-keepclassmembers class * extends android.view.View {
    *** get*();
    void set*(***);
}

# Keep layout inflation
-keepclassmembers class * extends android.view.LayoutInflater { *; }

# Keep gesture detectors and touch handlers
-keep class * extends android.view.GestureDetector { *; }
-keep class * extends android.view.ScaleGestureDetector { *; }
-keep class * extends android.view.VelocityTracker { *; }

# Keep animations and transitions
-keep class * extends android.animation.Animator { *; }
-keep class * extends android.animation.AnimatorListenerAdapter { *; }
-keep class * extends android.transition.Transition { *; }
-keep class android.animation.** { *; }
-keep class android.view.animation.** { *; }

# Keep graphics and drawables
-keep class android.graphics.** { *; }
-keep class * extends android.graphics.drawable.Drawable { *; }

# Keep accessibility support
-keep class * extends android.view.accessibility.AccessibilityNodeInfo { *; }
-keep class * extends android.view.accessibility.AccessibilityEvent { *; }

# Keep view state management
-keepclassmembers class * extends android.view.View {
    android.view.View$SavedState *;
    android.os.Parcelable onSaveInstanceState();
    void onRestoreInstanceState(android.os.Parcelable);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R8 from optimizing certain classes
-dontobfuscate
-dontoptimize
-dontshrink

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep the BuildConfig
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep all dependencies
-keep class androidx.** { *; }
-keep class com.google.android.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Kotlin specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep `Companion` object fields of serializable classes
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects of serializable classes
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.shell.** { *; }

# WebView related rules
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.in_app_browser.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.chrome_custom_tabs.** { *; }
-keep class * extends android.webkit.WebChromeClient { *; }
-keep class * extends android.webkit.WebViewClient { *; }

# Keep WebView JavaScript interfaces
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Application specific rules
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }
-keep class com.vertex.solar.MainActivity { *; }
-keep class com.vertex.solar.BuildConfig { *; }

# UI Components and Widgets
-keep class **.widget.** { *; }
-keep class **.ui.** { *; }
-keep class **.screen.** { *; }
-keep class **.page.** { *; }
-keep class **.view.** { *; }
-keep class **.animation.** { *; }
-keep class **.style.** { *; }
-keep class **.theme.** { *; }
-keep class **.design.** { *; }

# Keep all classes that might be used in XML layouts
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep custom views and their properties
-keepclassmembers class * extends android.view.View {
    *** get*();
    void set*(***);
}

# Keep layout inflation
-keepclassmembers class * extends android.view.LayoutInflater { *; }

# Keep gesture detectors and touch handlers
-keep class * extends android.view.GestureDetector { *; }
-keep class * extends android.view.ScaleGestureDetector { *; }
-keep class * extends android.view.VelocityTracker { *; }

# Keep animations and transitions
-keep class * extends android.animation.Animator { *; }
-keep class * extends android.animation.AnimatorListenerAdapter { *; }
-keep class * extends android.transition.Transition { *; }
-keep class android.animation.** { *; }
-keep class android.view.animation.** { *; }

# Keep graphics and drawables
-keep class android.graphics.** { *; }
-keep class * extends android.graphics.drawable.Drawable { *; }

# Keep accessibility support
-keep class * extends android.view.accessibility.AccessibilityNodeInfo { *; }
-keep class * extends android.view.accessibility.AccessibilityEvent { *; }

# Keep view state management
-keepclassmembers class * extends android.view.View {
    android.view.View$SavedState *;
    android.os.Parcelable onSaveInstanceState();
    void onRestoreInstanceState(android.os.Parcelable);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R8 from optimizing certain classes
-dontobfuscate
-dontoptimize
-dontshrink

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep the BuildConfig
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep all dependencies
-keep class androidx.** { *; }
-keep class com.google.android.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Kotlin specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep `Companion` object fields of serializable classes
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects of serializable classes
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.shell.** { *; }

# WebView related rules
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.in_app_browser.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.chrome_custom_tabs.** { *; }
-keep class * extends android.webkit.WebChromeClient { *; }
-keep class * extends android.webkit.WebViewClient { *; }

# Keep WebView JavaScript interfaces
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Application specific rules
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }
-keep class com.vertex.solar.MainActivity { *; }
-keep class com.vertex.solar.BuildConfig { *; }

# UI Components and Widgets
-keep class **.widget.** { *; }
-keep class **.ui.** { *; }
-keep class **.screen.** { *; }
-keep class **.page.** { *; }
-keep class **.view.** { *; }
-keep class **.animation.** { *; }
-keep class **.style.** { *; }
-keep class **.theme.** { *; }
-keep class **.design.** { *; }

# Keep all classes that might be used in XML layouts
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep custom views and their properties
-keepclassmembers class * extends android.view.View {
    *** get*();
    void set*(***);
}

# Keep layout inflation
-keepclassmembers class * extends android.view.LayoutInflater { *; }

# Keep gesture detectors and touch handlers
-keep class * extends android.view.GestureDetector { *; }
-keep class * extends android.view.ScaleGestureDetector { *; }
-keep class * extends android.view.VelocityTracker { *; }

# Keep animations and transitions
-keep class * extends android.animation.Animator { *; }
-keep class * extends android.animation.AnimatorListenerAdapter { *; }
-keep class * extends android.transition.Transition { *; }
-keep class android.animation.** { *; }
-keep class android.view.animation.** { *; }

# Keep graphics and drawables
-keep class android.graphics.** { *; }
-keep class * extends android.graphics.drawable.Drawable { *; }

# Keep accessibility support
-keep class * extends android.view.accessibility.AccessibilityNodeInfo { *; }
-keep class * extends android.view.accessibility.AccessibilityEvent { *; }

# Keep view state management
-keepclassmembers class * extends android.view.View {
    android.view.View$SavedState *;
    android.os.Parcelable onSaveInstanceState();
    void onRestoreInstanceState(android.os.Parcelable);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R8 from optimizing certain classes
-dontobfuscate
-dontoptimize
-dontshrink

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep the BuildConfig
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep all dependencies
-keep class androidx.** { *; }
-keep class com.google.android.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Kotlin specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep `Companion` object fields of serializable classes
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects of serializable classes
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.shell.** { *; }

# WebView related rules
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.in_app_browser.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.chrome_custom_tabs.** { *; }
-keep class * extends android.webkit.WebChromeClient { *; }
-keep class * extends android.webkit.WebViewClient { *; }

# Keep WebView JavaScript interfaces
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Application specific rules
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }
-keep class com.vertex.solar.MainActivity { *; }
-keep class com.vertex.solar.BuildConfig { *; }

# UI Components and Widgets
-keep class **.widget.** { *; }
-keep class **.ui.** { *; }
-keep class **.screen.** { *; }
-keep class **.page.** { *; }
-keep class **.view.** { *; }
-keep class **.animation.** { *; }
-keep class **.style.** { *; }
-keep class **.theme.** { *; }
-keep class **.design.** { *; }

# Keep all classes that might be used in XML layouts
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep custom views and their properties
-keepclassmembers class * extends android.view.View {
    *** get*();
    void set*(***);
}

# Keep layout inflation
-keepclassmembers class * extends android.view.LayoutInflater { *; }

# Keep gesture detectors and touch handlers
-keep class * extends android.view.GestureDetector { *; }
-keep class * extends android.view.ScaleGestureDetector { *; }
-keep class * extends android.view.VelocityTracker { *; }

# Keep animations and transitions
-keep class * extends android.animation.Animator { *; }
-keep class * extends android.animation.AnimatorListenerAdapter { *; }
-keep class * extends android.transition.Transition { *; }
-keep class android.animation.** { *; }
-keep class android.view.animation.** { *; }

# Keep graphics and drawables
-keep class android.graphics.** { *; }
-keep class * extends android.graphics.drawable.Drawable { *; }

# Keep accessibility support
-keep class * extends android.view.accessibility.AccessibilityNodeInfo { *; }
-keep class * extends android.view.accessibility.AccessibilityEvent { *; }

# Keep view state management
-keepclassmembers class * extends android.view.View {
    android.view.View$SavedState *;
    android.os.Parcelable onSaveInstanceState();
    void onRestoreInstanceState(android.os.Parcelable);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R8 from optimizing certain classes
-dontobfuscate
-dontoptimize
-dontshrink

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep the BuildConfig
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep all dependencies
-keep class androidx.** { *; }
-keep class com.google.android.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Kotlin specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep `Companion` object fields of serializable classes
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects of serializable classes
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep Flutter WebView classes
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.in_app_browser.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.chrome_custom_tabs.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.shell.** { *; }

# WebView related rules
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.in_app_browser.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.chrome_custom_tabs.** { *; }
-keep class * extends android.webkit.WebChromeClient { *; }
-keep class * extends android.webkit.WebViewClient { *; }

# Keep WebView JavaScript interfaces
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Application specific rules
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }
-keep class com.vertex.solar.MainActivity { *; }
-keep class com.vertex.solar.BuildConfig { *; }

# UI Components and Widgets
-keep class **.widget.** { *; }
-keep class **.ui.** { *; }
-keep class **.screen.** { *; }
-keep class **.page.** { *; }
-keep class **.view.** { *; }
-keep class **.animation.** { *; }
-keep class **.style.** { *; }
-keep class **.theme.** { *; }
-keep class **.design.** { *; }

# Keep all classes that might be used in XML layouts
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep custom views and their properties
-keepclassmembers class * extends android.view.View {
    *** get*();
    void set*(***);
}

# Keep layout inflation
-keepclassmembers class * extends android.view.LayoutInflater { *; }

# Keep gesture detectors and touch handlers
-keep class * extends android.view.GestureDetector { *; }
-keep class * extends android.view.ScaleGestureDetector { *; }
-keep class * extends android.view.VelocityTracker { *; }

# Keep animations and transitions
-keep class * extends android.animation.Animator { *; }
-keep class * extends android.animation.AnimatorListenerAdapter { *; }
-keep class * extends android.transition.Transition { *; }
-keep class android.animation.** { *; }
-keep class android.view.animation.** { *; }

# Keep graphics and drawables
-keep class android.graphics.** { *; }
-keep class * extends android.graphics.drawable.Drawable { *; }

# Keep accessibility support
-keep class * extends android.view.accessibility.AccessibilityNodeInfo { *; }
-keep class * extends android.view.accessibility.AccessibilityEvent { *; }

# Keep view state management
-keepclassmembers class * extends android.view.View {
    android.view.View$SavedState *;
    android.os.Parcelable onSaveInstanceState();
    void onRestoreInstanceState(android.os.Parcelable);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R8 from optimizing certain classes
-dontobfuscate
-dontoptimize
-dontshrink

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep the BuildConfig
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep all dependencies
-keep class androidx.** { *; }
-keep class com.google.android.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Kotlin specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep `Companion` object fields of serializable classes
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects of serializable classes
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.shell.** { *; }

# WebView related rules
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.in_app_browser.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.chrome_custom_tabs.** { *; }
-keep class * extends android.webkit.WebChromeClient { *; }
-keep class * extends android.webkit.WebViewClient { *; }

# Keep WebView JavaScript interfaces
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Application specific rules
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }
-keep class com.vertex.solar.MainActivity { *; }
-keep class com.vertex.solar.BuildConfig { *; }

# UI Components and Widgets
-keep class **.widget.** { *; }
-keep class **.ui.** { *; }
-keep class **.screen.** { *; }
-keep class **.page.** { *; }
-keep class **.view.** { *; }
-keep class **.animation.** { *; }
-keep class **.style.** { *; }
-keep class **.theme.** { *; }
-keep class **.design.** { *; }

# Keep all classes that might be used in XML layouts
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep custom views and their properties
-keepclassmembers class * extends android.view.View {
    *** get*();
    void set*(***);
}

# Keep layout inflation
-keepclassmembers class * extends android.view.LayoutInflater { *; }

# Keep gesture detectors and touch handlers
-keep class * extends android.view.GestureDetector { *; }
-keep class * extends android.view.ScaleGestureDetector { *; }
-keep class * extends android.view.VelocityTracker { *; }

# Keep animations and transitions
-keep class * extends android.animation.Animator { *; }
-keep class * extends android.animation.AnimatorListenerAdapter { *; }
-keep class * extends android.transition.Transition { *; }
-keep class android.animation.** { *; }
-keep class android.view.animation.** { *; }

# Keep graphics and drawables
-keep class android.graphics.** { *; }
-keep class * extends android.graphics.drawable.Drawable { *; }

# Keep accessibility support
-keep class * extends android.view.accessibility.AccessibilityNodeInfo { *; }
-keep class * extends android.view.accessibility.AccessibilityEvent { *; }

# Keep view state management
-keepclassmembers class * extends android.view.View {
    android.view.View$SavedState *;
    android.os.Parcelable onSaveInstanceState();
    void onRestoreInstanceState(android.os.Parcelable);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R8 from optimizing certain classes
-dontobfuscate
-dontoptimize
-dontshrink

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep the BuildConfig
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep all dependencies
-keep class androidx.** { *; }
-keep class com.google.android.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Kotlin specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep `Companion` object fields of serializable classes
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects of serializable classes
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep Flutter WebView classes
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.in_app_browser.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.chrome_custom_tabs.** { *; }

# Keep WebView JavaScript interfaces
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep all classes in your app package
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep all classes that might be used in XML layouts
-keep public class * extends android.view.View
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.preference.Preference
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# Keep R8 from optimizing certain classes
-dontobfuscate
-dontoptimize
-dontshrink

# Keep source file names for better crash reports
-keepattributes SourceFile,LineNumberTable

# Keep JavaScript interfaces
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.shell.** { *; }

# Keep all your custom widgets and UI components
-keep class **.widget.** { *; }
-keep class **.ui.** { *; }
-keep class **.screen.** { *; }
-keep class **.page.** { *; }
-keep class **.view.** { *; }

# Keep your application classes
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }

# Kotlin specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep `Companion` object fields of serializable classes.
# This avoids serializer lookup through `getDeclaredClasses` as done for named companion objects.
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects (both default and named) of serializable classes.
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep the Flutter entry point
-keep class com.vertex.solar.MainActivity { *; }

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep WebView related
-keep class * extends android.webkit.WebChromeClient { *; }
-keep class * extends android.webkit.WebViewClient { *; }

# Preserve all fundamental application classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference

# Preserve all classes that have special context constructors, and the ones
# that are referenced by xml files
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep UI-related classes
-keep class **.ui.** { *; }
-keep class **.widget.** { *; }
-keep class **.screen.** { *; }
-keep class **.view.** { *; }
-keep class **.animation.** { *; }
-keep class **.style.** { *; }
-keep class **.theme.** { *; }
-keep class **.design.** { *; }

# Keep all your Dart classes
-keep class **.dart.** { *; }

# Keep all enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep the BuildConfig
-keep class com.vertex.solar.BuildConfig { *; }

# Keep all animation and graphics related classes
-keep class android.animation.** { *; }
-keep class android.graphics.** { *; }
-keep class android.view.animation.** { *; }

# Keep all resources
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep all dependencies
-keep class androidx.** { *; }
-keep class com.google.android.** { *; }

# Disable obfuscation
-dontobfuscate

# Keep all constructors that might be used by Flutter
-keepclasseswithmembers class * {
    public <init>(android.content.Context);
}

# Keep all classes that use platform views
-keep class io.flutter.plugin.platform.** { *; }

# Keep all classes that handle UI effects
-keep class android.graphics.drawable.** { *; }
-keep class android.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
# Keep Flutter WebView classes
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.in_app_browser.** { *; }
-keep class com.pichillilorenzo.flutter_inappwebview.chrome_custom_tabs.** { *; }

# Keep WebView JavaScript interfaces
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep all classes in your app package
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep all classes that might be used in XML layouts
-keep public class * extends android.view.View
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.preference.Preference
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# Keep R8 from optimizing certain classes
-dontobfuscate
-dontoptimize
-dontshrink

# Keep source file names for better crash reports
-keepattributes SourceFile,LineNumberTable

# Keep JavaScript interfaces
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.shell.** { *; }

# Keep all your custom widgets and UI components
-keep class **.widget.** { *; }
-keep class **.ui.** { *; }
-keep class **.screen.** { *; }
-keep class **.page.** { *; }
-keep class **.view.** { *; }

# Keep your application classes
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }

# Kotlin specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep `Companion` object fields of serializable classes.
# This avoids serializer lookup through `getDeclaredClasses` as done for named companion objects.
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects (both default and named) of serializable classes.
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep the Flutter entry point
-keep class com.vertex.solar.MainActivity { *; }

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep WebView related
-keep class * extends android.webkit.WebChromeClient { *; }
-keep class * extends android.webkit.WebViewClient { *; }

# Preserve all fundamental application classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference

# Preserve all classes that have special context constructors, and the ones
# that are referenced by xml files
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep UI-related classes
-keep class **.ui.** { *; }
-keep class **.widget.** { *; }
-keep class **.screen.** { *; }
-keep class **.view.** { *; }
-keep class **.animation.** { *; }
-keep class **.style.** { *; }
-keep class **.theme.** { *; }
-keep class **.design.** { *; }

# Keep all your Dart classes
-keep class **.dart.** { *; }

# Keep all enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep the BuildConfig
-keep class com.vertex.solar.BuildConfig { *; }

# Keep all animation and graphics related classes
-keep class android.animation.** { *; }
-keep class android.graphics.** { *; }
-keep class android.view.animation.** { *; }

# Keep all resources
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep all dependencies
-keep class androidx.** { *; }
-keep class com.google.android.** { *; }

# Disable obfuscation
-dontobfuscate

# Keep all constructors that might be used by Flutter
-keepclasseswithmembers class * {
    public <init>(android.content.Context);
}

# Keep all classes that use platform views
-keep class io.flutter.plugin.platform.** { *; }

# Keep all classes that handle UI effects
-keep class android.graphics.drawable.** { *; }
-keep class android.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.view.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.android.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.embedding.engine.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.shell.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.app.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.plugin.** { *; }

# Keep all Flutter plugins
-keep class io.flutter.util.** { *; }

# Keep all Flutter plugins
# Keep all your custom widgets and UI components
-keep class **.widget.** { *; }
-keep class **.ui.** { *; }
-keep class **.screen.** { *; }
-keep class **.page.** { *; }
-keep class **.view.** { *; }

# Keep your application classes
-keep class com.vertex.solar.** { *; }
-keepclassmembers class com.vertex.solar.** { *; }

# Kotlin specific rules
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Keep `Companion` object fields of serializable classes.
# This avoids serializer lookup through `getDeclaredClasses` as done for named companion objects.
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects (both default and named) of serializable classes.
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep the Flutter entry point
-keep class com.vertex.solar.MainActivity { *; }

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep WebView related
-keep class * extends android.webkit.WebChromeClient { *; }
-keep class * extends android.webkit.WebViewClient { *; }

# Preserve all fundamental application classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference

# Preserve all classes that have special context constructors, and the ones
# that are referenced by xml files
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile 