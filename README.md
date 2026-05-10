# ClassicCode

ClassicCode is a small remote-control skeleton for old Apple targets:

- OS X 10.6-compatible host/server code built on an OS X 10.9 machine.
- iOS 6-compatible UIKit client code built with Xcode 4.6.3 and the iOS 6.1 SDK.
- A shared line-oriented wire protocol that is intentionally simple enough to debug over SSH and netcat.

The current tree is a buildable foundation, not a finished remote-control product.

The implementation plan and backend boundary live in [docs/implementation-plan.md](docs/implementation-plan.md). In short: the long-term backend is `codex remote-control`; the current `ClassicCodeHost` is a temporary compatibility shim for old-platform build, deployment, transport, and UI smoke tests.

## Layout

```text
Makefile
docs/implementation-plan.md
Resources/iOS/Info.plist
Sources/Host/ClassicCodeHost.m
Sources/Shared/CCWire.h
Sources/Shared/CCWire.m
Sources/iOS/CCAppDelegate.h
Sources/iOS/CCAppDelegate.m
Sources/iOS/CCRemoteClient.h
Sources/iOS/CCRemoteClient.m
Sources/iOS/main.m
scripts/build-on-10.9.sh
scripts/deploy-ios6-app.sh
```

## Build Host

The verified build host is:

```text
classiccode-mac109 -> 10.1.100.96
Mac OS X 10.9.5
Xcode 4.6.3
iPhoneOS6.1.sdk
MacOSX10.7.sdk
```

Build from the current Mac by syncing this checkout to the build host:

```sh
scripts/build-on-10.9.sh
```

Or build directly on the 10.9 machine from the synced checkout:

```sh
make clean all
```

## Artifacts

```text
build/macosx/ClassicCodeHost
build/iphoneos/ClassicCodeClient.app
```

## Smoke Test

On the 10.9 build host:

```sh
make run-host
```

The host listens on `127.0.0.1:17390` by default and supports:

```text
HELLO
PING
INFO
HELP
QUIT
```

The iOS client defaults to `127.0.0.1:17390`; change the host field in the UI when using a port forward.

## iPad Deployment

The verified iOS 6 device is reachable from the 10.9 host through the local reverse SSH tunnel alias:

```text
classiccode-ipad6-via-local
```

To deploy the app bundle from the build host through that alias:

```sh
scripts/deploy-ios6-app.sh
```

The deploy script copies `ClassicCodeClient.app` to `/Applications/ClassicCodeClient.app` on the iPad and refreshes SpringBoard icons when `uicache` is present.
