.PHONY: all
all: test lint

.PHONY: test
test:
	flutter test

.PHONY: lint
lint:
	dart analyze

.PHONY: demo-chrome
demo-chrome:
	cd example; flutter -d chrome run

.PHONY: demo-android
demo-android:
	# For android, connect your device, enable dev options,
	# and allow file transfer over USB.
	# See `flutter devices` for possible `-d` arguments.
	cd example; flutter -d pixel run
