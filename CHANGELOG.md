## [1.6.7](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.6.6...v1.6.7) (2026-06-25)


### Bug Fixes

* prevent websocket server restart if already running and log session metadata ([bfe0363](https://github.com/tachibana-shin/koreader_remote_turner/commit/bfe0363123378cdfb235811f18f72e0ee385f177))

## [1.6.6](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.6.5...v1.6.6) (2026-06-25)


### Bug Fixes

* implement background foreground service for volume key handling and refine WebSocket communication logic ([db6d893](https://github.com/tachibana-shin/koreader_remote_turner/commit/db6d893551352e8136f7d5c79ff52afc5a3dd806))

## [1.6.5](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.6.4...v1.6.5) (2026-06-25)


### Bug Fixes

* migrate volume event handling from MethodChannel to EventChannel and clean up server configuration ([eb193a5](https://github.com/tachibana-shin/koreader_remote_turner/commit/eb193a5ed0bd3fb5ae8b956bbb6ea2f41749061c))

## [1.6.4](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.6.3...v1.6.4) (2026-06-25)


### Bug Fixes

* simplify event dispatching in Android and standardize WebSocket server lifecycle management ([138f4d3](https://github.com/tachibana-shin/koreader_remote_turner/commit/138f4d3f430784d9ebe93796bb8342c063992c9f))

## [1.6.3](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.6.2...v1.6.3) (2026-06-25)


### Bug Fixes

* add retry logic with fallback to shared binding for websocket server startup ([df502b6](https://github.com/tachibana-shin/koreader_remote_turner/commit/df502b61010376875c40d6f4392a149daf15bfed))

## [1.6.2](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.6.1...v1.6.2) (2026-06-25)


### Bug Fixes

* **android:** prevent device sleep for service ([1e1d5c7](https://github.com/tachibana-shin/koreader_remote_turner/commit/1e1d5c785d77bacac7dc10f97f7916ae9a12a54b))

## [1.6.1](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.6.0...v1.6.1) (2026-06-25)


### Bug Fixes

* android f ([e91a966](https://github.com/tachibana-shin/koreader_remote_turner/commit/e91a9662a649d47a4a1789b450a8211b057bc522))

# [1.6.0](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.5.3...v1.6.0) (2026-06-25)


### Features

* add foreground service support for Android background execution ([b3d8eea](https://github.com/tachibana-shin/koreader_remote_turner/commit/b3d8eea93f1a67d79bcba45ea6bc0af7896b3a0c))

## [1.5.3](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.5.2...v1.5.3) (2026-06-25)


### Bug Fixes

* remove native volume key dispatching and handle volume stream subscription within the app lifecycle ([9148b2c](https://github.com/tachibana-shin/koreader_remote_turner/commit/9148b2c949180542c882bc0efafab330e6d3f18e))

## [1.5.2](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.5.1...v1.5.2) (2026-06-25)


### Bug Fixes

* replace BackgroundService with EventBus singleton for event dispatching ([2b0a060](https://github.com/tachibana-shin/koreader_remote_turner/commit/2b0a06050177e1274670aa47c4d11dc279353c0c))

## [1.5.1](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.5.0...v1.5.1) (2026-06-25)


### Bug Fixes

* sync state kt-dart ([e1da448](https://github.com/tachibana-shin/koreader_remote_turner/commit/e1da448250bfbb184fe62e6564cd82c6867c50da))

# [1.5.0](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.4.0...v1.5.0) (2026-06-25)


### Features

* configure accessibility service for volume key hardware events and update service manifest ([c84972e](https://github.com/tachibana-shin/koreader_remote_turner/commit/c84972eb6674975c037db692aede791dd81296fd))

# [1.4.0](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.3.0...v1.4.0) (2026-06-25)


### Bug Fixes

* nullify ws_client upon disconnection and remove redundant nil assignments in poll callbacks ([eb00764](https://github.com/tachibana-shin/koreader_remote_turner/commit/eb00764690b029f548b7fe0b8815ae90b687a495))
* **remote-turner:** improve websocket disconnect handling ([8d188b5](https://github.com/tachibana-shin/koreader_remote_turner/commit/8d188b5db06bec34e367d06f3bb9b1a90ef88524))
* update BackgroundService and RemoteTurnerApplication to support volume key event handling ([370acd8](https://github.com/tachibana-shin/koreader_remote_turner/commit/370acd86654a95be0c63dde3ce67e2c13e039d9e))


### Features

* implement lifecycle listener for automatic keyboard service toggling and remove redundant startup calls ([e3d3f3f](https://github.com/tachibana-shin/koreader_remote_turner/commit/e3d3f3f466868ab0703851c5fb42d521de3b235b))

# [1.3.0](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.2.0...v1.3.0) (2026-06-24)


### Features

* add log clearing functionality and implement persistent app bar with navigation titles ([9b1304c](https://github.com/tachibana-shin/koreader_remote_turner/commit/9b1304c3d569b98a6d54c5159f72c7af3c0ebbe3))

# [1.2.0](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.1.0...v1.2.0) (2026-06-24)


### Features

* implement UDP discovery service, improve event handling with a queue, and optimize volume key event dispatching. ([086c1f8](https://github.com/tachibana-shin/koreader_remote_turner/commit/086c1f86fbbde6337e2df4ce610f282675354d5e))

# [1.1.0](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.0.2...v1.1.0) (2026-06-24)


### Features

* add INTERNET permission to Android manifest ([c5fc386](https://github.com/tachibana-shin/koreader_remote_turner/commit/c5fc38635b5559b98b86cfa5dbfab0daa2400d6c))

## [1.0.2](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.0.1...v1.0.2) (2026-06-24)


### Bug Fixes

* android network permission ([e3fd82d](https://github.com/tachibana-shin/koreader_remote_turner/commit/e3fd82d70224bf6d537c49c7bb46be710f12f9f5))
* macos build fail ([dc50fab](https://github.com/tachibana-shin/koreader_remote_turner/commit/dc50fab3363b81b6e8af54487aa3f51ef261d595))

## [1.0.1](https://github.com/tachibana-shin/koreader_remote_turner/compare/v1.0.0...v1.0.1) (2026-06-24)


### Bug Fixes

* ci release ipa ([bf9c717](https://github.com/tachibana-shin/koreader_remote_turner/commit/bf9c71711e81e8ac7a41d5e115303215f6e56007))
* ios crash method ([e3a834c](https://github.com/tachibana-shin/koreader_remote_turner/commit/e3a834cac0b2f25656c66e44f22ca351e82c71bd))

# 1.0.0 (2026-06-24)


### Features

* add background service and release pipeline ([d4065f4](https://github.com/tachibana-shin/koreader_remote_turner/commit/d4065f4f60e7cd1ae5448bd1de17747c6628810b))
* **android:** add background volume interception ([17f993e](https://github.com/tachibana-shin/koreader_remote_turner/commit/17f993e32c209677dcc851cdec71f4b7e6abd473))
* **ci:** add multi-arch support for build pipeline ([9a789ec](https://github.com/tachibana-shin/koreader_remote_turner/commit/9a789ec05fafc7c1410f5b55df272dd2130fd3a2))

# 1.0.0 (2026-06-24)


### Features

* add background service and release pipeline ([d4065f4](https://github.com/tachibana-shin/koreader_remote_turner/commit/d4065f4f60e7cd1ae5448bd1de17747c6628810b))

# Changelog

All notable changes to this project will be documented in this file.
