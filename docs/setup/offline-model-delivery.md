# Offline Model Delivery & Asset Packaging Guide

GrammarFix uses a hybrid engine architecture:
1. **English Harper Engine**: Packaged with app binary (~5MB, native Rust C-ABI).
2. **Multilingual Qwen3 Pack**: On-demand dynamic asset delivery pack (~475MB) via Google Play Feature Delivery / Asset Delivery.

---

## Google Play Asset Delivery (PAD) Configuration

In `android/` build system, the multilingual weights are packaged as an `on-demand` asset pack:

```groovy
// android/multilingual_pack/build.gradle
plugins {
    id 'com.android.asset-pack'
}

assetPack {
    packName = "multilingual_pack"
    dynamicDelivery {
        deliveryType = "on-demand"
    }
}
```

### Storage and Memory Guidelines

- **Storage Location**: `context.getExternalFilesDir("models/qwen_gec_int4.bin")` or `assetPackManager.getPackLocation("multilingual_pack")`.
- **RAM Footprint**: ~650 MB peak RAM during LiteRT-LM model execution.
- **16 KB Memory Page Alignment**: Ensure `libharper_bridge.so` and `liblitert_lm.so` are built with `-Wl,-z,max-page-size=16384` for Android 15+ compatibility.
