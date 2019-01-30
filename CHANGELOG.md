# Changelog

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
