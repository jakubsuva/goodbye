#!/bin/sh
# Everything that can be verified without Xcode: typecheck the app, run the arithmetic tests.
set -e
cd "$(dirname "$0")/.."
SDK="$(xcrun --sdk macosx --show-sdk-path)"
echo "--- typecheck ---"
xcrun swiftc -typecheck -parse-as-library -target arm64-apple-macos15.0 -sdk "$SDK" \
  $(find Goodbye -name '*.swift' | sort)
echo "--- arithmetic tests ---"
xcrun swiftc -sdk "$SDK" -target arm64-apple-macos15.0 -o /tmp/goodbye-check \
  Goodbye/Models/Rhythm.swift Goodbye/Models/Hue.swift Goodbye/Models/Suggestions.swift Goodbye/Models/Records.swift \
  Goodbye/Models/Ledger.swift Goodbye/Models/Tally.swift Tools/ledger-check/main.swift
/tmp/goodbye-check
echo "--- store + reminders tests ---"
xcrun swiftc -parse-as-library -sdk "$SDK" -target arm64-apple-macos15.0 -o /tmp/goodbye-store-check \
  Goodbye/Models/Rhythm.swift Goodbye/Models/Hue.swift Goodbye/Models/Suggestions.swift Goodbye/Models/Records.swift \
  Goodbye/Models/Ledger.swift Goodbye/Models/Tally.swift Goodbye/Store.swift Goodbye/Reminders.swift \
  Tools/store-check/StoreCheck.swift
/tmp/goodbye-store-check
