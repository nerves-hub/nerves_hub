# Changelog

## v0.5.1

* Bug fixes
  * Increased download hang timeout to deal with slow networks and <1 minute
    long hiccups
  * Fixed naming collision with a named process

## v0.5.0

* Enhancements
  * nerves_hub_cli: Bump to v0.7.0
  * The Phoenix Channel connection no longer uses the topic `firmware:firmware_uuid`
    and instead connects to the topic `device`.

## v0.4.0

This release has backwards incompatible changes so please read carefully.

The configuration key for firmware signing keys has changed from `:public_keys`
to `:fwup_public_keys`.

If you are not using nerves-hub.org for your NervesHub server, the configuration
keys for specifying the device endpoint for the server have changed. Look for
`:device_api_host` and `:device_api_port` in the documentation and example for
setting these.

* Enhancements
  * All firmware metadata is now passed up to the NervesHub. This will make it
    possible for the server to make decisions on firmware that has been loaded
    outside of NervesHub or old firmware that has been unloaded from NervesHub.
  * Code cleanup and refactoring throughout. More passes are planned.

## v0.3.0

* Enhancements
  * Add uuid and dn to http headers for polling requests

* Bug fixes
  * Fix crash when no updates were available

## v0.2.1

* Bug fixes
  * Use CA certificates from `:nerves_hub` instead of `:nerves_hub_core`.

## v0.2.0

* Enhancements
  * Updated docs.
  * Added support for [NervesKey](https://github.com/nerves-hub/nerves_key).
  * Added support for performing conditional updates.
  * Include `fwup` elixir dependency for interfacing with `fwup`.
  * Update deps and code to make it possible to run on host for testing.
  * Automatically call `NervesHub.connect()` instead of requiring it to be specified.
  * Improved error handling and reporting.

## v0.1.0

Initial release
