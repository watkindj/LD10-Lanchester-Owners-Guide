# LD10 – Lanchester Owners' Guide

This is an iOS SwiftUI project prepared for the supplied website backup. The 291 MB original archive is intentionally not duplicated in this small source download.

## What's included
- A modern native SwiftUI home screen with sections for maintenance, technical information, trim, spares, owners' cars, photographs and contact.
- Add the supplied `LD10 Website (working) 21-12-2022.zip` as `LD10/Resources/LD10-Website-Backup.zip`; the app unpacks it on first launch.
- Original HTML pages, linked images, PDFs and supporting assets remain in their original folder structure and are browsable offline through WKWebView.
- ZIPFoundation is fetched by Swift Package Manager when Xcode resolves packages.

## Build
1. Open `LD10.xcodeproj` in Xcode on a Mac, or upload this project to a supported cloud iOS build service.
2. Resolve Swift Package dependencies.
3. Select an iOS Simulator or a registered device and build.

For TestFlight/App Store distribution, the Apple Developer Program paid membership and signing setup are required. A free Apple developer account does not provide TestFlight distribution.

## Important
- The supplied source archive is from 21 December 2022. The app preserves its content; it does not verify that all information is current.
- The source site's attribution and copyright notices are retained in the original pages.
- This is a starter build project. It has not been compiled or signed in this environment.
