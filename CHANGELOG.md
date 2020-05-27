# v4.1.3
## 27 May 2020 — 05:51:30 UTC

### other

+ __\*:__ fix: Updates for coldbox@6
 ([7755c84](https://github.com/coldbox-modules/cbguard/commit/7755c84fbcd7807e5b5d7b07d42b1025ad4c041c))


# v4.1.2
## 12 May 2020 — 16:06:46 UTC

### chore

+ __CI:__ Update Travis testing matrix
 ([5793f0f](https://github.com/coldbox-modules/cbguard/commit/5793f0fc3b1e7a0abba5ec3ede7f814df94180cf))

### other

+ __\*:__ feat: Add _securedUrl to flash scope on overrides
 ([731113b](https://github.com/coldbox-modules/cbguard/commit/731113b2bc890052fc9d295a306292dcefb7c0c7))


# v4.1.1
## 24 Mar 2020 — 19:17:22 UTC

### other

+ __\*:__ chore: Add automatic formatting
 ([9246b00](https://github.com/coldbox-modules/cbguard/commit/9246b00a7d5925e534cf020b0e346ae37ca9fa43))
+ __\*:__ chore: Test on coldbox@be in CI as well
 ([d09141f](https://github.com/coldbox-modules/cbguard/commit/d09141f62a099ec65e05943eadd416d6b4c8eafc))
+ __\*:__ fix: Don't trigger ColdBox's invalid event looping protection ([41093f7](https://github.com/coldbox-modules/cbguard/commit/41093f77ec316dcc145cc34eb25af972a59dbb27))


# v4.1.0
## 19 Mar 2020 — 20:49:31 UTC

### feat

+ __Guard:__ Add a guard service that can authorize anywhere during the request ([0602b9b](https://github.com/coldbox-modules/cbguard/commit/0602b9b9f351c9f7d9ba0818d966ea6ab91c7eb6))
+ __Guard:__ Add a guard service that can authorize anywhere during the request ([d5cba31](https://github.com/coldbox-modules/cbguard/commit/d5cba31789b7e478c86caaf1acdc412c00ad2ae7))

### other

+ __\*:__ Add information on defining custom guards
 ([36c6f63](https://github.com/coldbox-modules/cbguard/commit/36c6f63432d262a4cc5c1f7f0c0ec34ae3bd047b))


# v4.0.1
## 13 Feb 2020 — 17:18:56 UTC

### other

+ __\*:__ chore: Use forgeboxStorage ([aae5e7b](https://github.com/coldbox-modules/cbguard/commit/aae5e7bdd550d6304c863139ab9aaa001ed5a856))


# v4.0.0
## 29 Oct 2019 — 16:20:50 UTC

### BREAKING

+ __\*:__ feat: Ability to use local override handlers if they exist ([f4ab223](https://github.com/coldbox-modules/cbguard/commit/f4ab2231e3a3b7d52d8e31c79bafc348e08265e5))


# v3.1.0
## 10 Sep 2019 — 21:47:20 UTC

### feat

+ __ModuleConfig:__ Add a flag to prevent automatic registration ([7d376f3](https://github.com/coldbox-modules/cbguard/commit/7d376f341d2ba870fb16ff9d5d35a0800243a9ef))

### fix

+ __SecuredEventInterceptor:__ Ignore OPTIONS requests ([c29810f](https://github.com/coldbox-modules/cbguard/commit/c29810f680c1e6e4c42223ebf2f95f6d2d45ff2a))


# v3.0.0
## 05 Sep 2019 — 19:09:13 UTC

### BREAKING

+ __cbguard:__ Use ColdBox 5.6's handler metadata cache ([72ba3d0](https://github.com/coldbox-modules/cbguard/commit/72ba3d054cb74e39d073f1aded8207bf0c4d97ec))

### feat

+ __cbguard:__ Allow for per-module overrides of cbguard settings ([2dbdc53](https://github.com/coldbox-modules/cbguard/commit/2dbdc53ce61295275f4170868f49e8f8e7bb8bd6))

### fix

+ __cbguard:__ Ensure implicit view events are still allowed ([01d065e](https://github.com/coldbox-modules/cbguard/commit/01d065e349374762f3bba24341393c54baadf1d8))


# v2.0.0
## 16 Aug 2019 — 04:47:13 UTC

### BREAKING

+ __SecuredEventInterceptor:__ Relocate by default for non-ajax events ([8075b45](https://github.com/coldbox-modules/cbguard/commit/8075b458fc25f93a6816d2b2f1e9424df5236526))
+ __build:__ Remove ACF 10 and ColdBox 4 support ([b199f66](https://github.com/coldbox-modules/cbguard/commit/b199f66db81d66bc78d9a230b6f10c574f7eb239))

### build

+ __box.json:__ Remove publish actions in favor of commandbox-semantic-release
 ([ed2c53b](https://github.com/coldbox-modules/cbguard/commit/ed2c53b31b529b3b7f6b72282a2c5f98ca9e6006))
+ __travis:__ Use openjdk instead of oracle
 ([81f9b45](https://github.com/coldbox-modules/cbguard/commit/81f9b45a37f7486179436f1c5b49013f3eeadf02))
+ __csr:__ Set up commandbox-semantic-release
 ([c4f6077](https://github.com/coldbox-modules/cbguard/commit/c4f6077b0472bfb5dcdd83556c3f2fdcbe267be3))

### other

+ __\*:__ chore: Remove jmimemagic.log
 ([0a7f7e0](https://github.com/coldbox-modules/cbguard/commit/0a7f7e07a92994cc558ec612c3eda5d821f6c17a))
