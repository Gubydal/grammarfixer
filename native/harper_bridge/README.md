# Harper Native Bridge (`harper_bridge`)

This directory contains the Rust C-ABI native bridge connecting Flutter to `harper-core` (Apache-2.0) on Android.

## Architecture

```text
Flutter (Dart FFI)
  ↓
libharper_bridge.so (C-ABI)
  ↓
harper-core (Rust)
```

## Supported ABIs
- `arm64-v8a` (`aarch64-linux-android`)
- `armeabi-v7a` (`armv7-linux-androideabi`)
- `x86_64` (`x86_64-linux-android`)
- `x86` (`i686-linux-android`)

## Building for Android with 16 KB Page Alignment

To build compliant `.so` binaries for Google Play 16 KB memory alignment requirements:

```powershell
# Install cargo-ndk
cargo install cargo-ndk

# Add Android targets
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android

# Build for arm64-v8a with 16KB alignment flags
RUSTFLAGS="-C link-arg=-Wl,-z,max-page-size=16384" cargo ndk -t arm64-v8a -o ../../android/app/src/main/jniLibs build --release
```

## Testing

Run native unit tests with:
```powershell
cargo test
```
