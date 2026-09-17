-include .env

SUPABASE_URL ?= http://127.0.0.1:54321
SUPABASE_PUBLISHABLE_KEY ?= sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
FLUTTER_DEVICE ?=
AUTH_MODE ?= local
DEVICE_ARG = $(if $(strip $(FLUTTER_DEVICE)),-d $(FLUTTER_DEVICE),)
SUPABASE_DEFINES = --dart-define=SUPABASE_URL=$(SUPABASE_URL) \
	--dart-define=SUPABASE_PUBLISHABLE_KEY=$(SUPABASE_PUBLISHABLE_KEY)
AUTH_DEFINE = --dart-define=AUTH=$(AUTH_MODE)

.PHONY: dev mock db-reset

dev:
	supabase start
	flutter run $(DEVICE_ARG) --dart-define=ENV=dev \
		--dart-define=ENGINE=remote $(AUTH_DEFINE) $(SUPABASE_DEFINES)

mock:
	flutter run $(DEVICE_ARG) --dart-define=ENV=dev \
		--dart-define=ENGINE=mock $(AUTH_DEFINE) $(SUPABASE_DEFINES)

db-reset:
	supabase db reset
