.PHONY: run run-android pub-get clean build-apk-arm64

run:
	flutter run -d linux --dart-define=DEVICE_PREVIEW=true

run-android:
	@flutter devices | rg -qi "android" || (echo "No Android device/emulator detected. Connect a phone (USB debugging) or start an emulator."; exit 1)
	flutter run -d android

pub-get:
	flutter pub get

clean:
	flutter clean

build-apk-arm64:
	flutter build apk --release --target-platform android-arm64
