.PHONY: run pub-get clean build-apk-arm64

run:
	flutter run

pub-get:
	flutter pub get

clean:
	flutter clean

build-apk-arm64:
	flutter build apk --release --target-platform android-arm64
