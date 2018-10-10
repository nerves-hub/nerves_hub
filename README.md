# NervesHub

[![CircleCI](https://circleci.com/gh/nerves-hub/nerves_hub/tree/master.svg?style=svg)](https://circleci.com/gh/nerves-hub/nerves_hub/tree/master)
[![Hex version](https://img.shields.io/hexpm/v/nerves_hub.svg "Hex version")](https://hex.pm/packages/nerves_hub)

This directory contains the official client for interacting with the NervesHub
server as a device.

## Getting Started

### Adding NervesHub to your project

Start by adding `nerves_hub` to your target dependencies in your `mix.exs` file.
NervesHub uses SSL certificates to secure communication between the device and
the server. It is important that the time on the device is set for SSL to
function properly. If you are not already setting the time, you can also include
`nerves_time`.

```elixir
  defp deps(target) do
    [
      {:nerves_runtime, "~> 0.6"},
      {:nerves_init_gadget, "~> 0.4"},
      {:nerves_hub, "~> 0.1"}
    ] ++ system(target)
  end
```

Update your config for `:nerves` `:firmware` to delegate `:provisioning` to
`:nerves_hub`. This will be helpful later on when programming the firmware on a
device for the first time.

```elixir
config :nerves, :firmware,
  rootfs_overlay: "rootfs_overlay",
  provisioning: :nerves_hub
```

Make sure your device connects automatically to
[nerves-hub.org](https://nerves-hub.org) by adding NervesHub.connect() to the
start function of your Application module:

```elixir
  defmodule Example.Application do
    use Application

    def start(_type, _args) do
      NervesHub.connect()

      opts = [strategy: :one_for_one, name: Example.Supervisor]
      Supervisor.start_link(children(@target), opts)
    end
  end
```

### Setting up the CLI

While you can use the [NervesHub](https://nerves-hub.org) website to manage
devices, many operations are more convenient when run through the CLI. We
recommend adding the [nerves_hub_cli](https://hex.pm/packages/nerves_hub_cli)
package to your dependency list as follows:

```elixir
  defp deps do
    [
      {:nerves, "~> 1.3", runtime: false},
      {:nerves_hub_cli, "~> 0.1", runtime: false}
      ...
    ] ++ deps(@target)
  end
```

Run `mix deps.get` to download the `nerves_hub_cli` dependency.

A NervesHub account is required to use the CLI. Create a new account by running:

```bash
mix nerves_hub.user register
```

If you have an account, authenticate by running:

```bash
mix nerves_hub.user auth
```

### Creating a NervesHub product

A NervesHub product groups devices that run the same kind of firmware. All
devices and firmware images have a product. NervesHub provides finer grain
mechanisms for grouping devices, but a product is needed to get started.

By default, NervesHub uses the `:app` name in your `mix.exs` for the product
name. If you would like it to use a different name, add a `:name` field to your
`Mix.Project.config()`. For example, NervesHub would use "My Example" instead of
"example" for the following project:

```elixir
  def project do
    [
      app: :example,
      name: "My Example"
    ]
  end
```

For the remainder of this document, though, we will not use the `:name` field
and simply use the product name `example`.

Create a new product on NervesHub by running:

```bash
mix nerves_hub.product create
```

### Creating NervesHub firmware signing keys

NervesHub requires cryptographic signatures on all managed firmware. Devices
receiving firmware from NervesHub validate signatures. Since firmware is signed
before uploading to NervesHub, NervesHub or any service NervesHub uses cannot
modify it.

Firmware authentication uses [Ed25519 digital
signatures](https://en.wikipedia.org/wiki/EdDSA#Ed25519). You need to create at
least one public/private key pair and copy the public key part to NervesHub and
to devices. NervesHub tooling helps with both. A typical setup has multiple
signing keys to support key rotation and "development" keys that are not as
protected.

Start by creating a `devkey` firmware signing key pair:

```bash
mix nerves_hub.key create devkey
```

On success, you'll see the public key. You can confirm using the NervesHub web
interface that the signing key exists.

Next, add the key's name to your `config.exs` so that it can be built into your
firmware image:

```elixir
config :nerves_hub,
  public_keys: [:devkey]
```

The `nerves_hub` dependency converts key names to public keys at compile time.
If you haven't compiled your project yet, run `mix firmware` now. If you have
compiled it, `mix` won't know to recompile `nerves_hub` due to the configuration
change. Force it to recompile by running:

```bash
mix deps.compile nerves_hub --force
mix firmware
```

### Publishing firmware

Uploading firmware to NervesHub is called publishing. To publish firmware start
by calling:

```bash
mix firmware
```

Firmware can only be published if has been signed. You can sign the firmware by
running.

```bash
mix nerves_hub.firmware sign --key devkey
```

Firmware can also be signed while publishing:

```bash
mix nerves_hub.firmware publish --key devkey
```

### Initializing devices

In this example we will create a device with a hardware identifier `1234`.  The
device will also be tagged with `qa` so we can target it in our deployment
group. We will select `y` when asked if we would like to generate device
certificates. Device certificates are required for a device to establish a
connection with the NervesHub server.

```bash
$ mix nerves_hub.device create

NervesHub org: nerveshub
identifier: 1234
description: test-1234
tags: qa
Local user password:
Device 1234 created
Would you like to generate certificates? [Yn] y
Creating certificate for 1234
Finished
```

It is important to note that device certificate private keys are generated and
stay on your host computer. A certificate signing request is sent to the server,
and a signed public key is passed back. Generated certificates will be placed in
a folder titled `nerves-hub` in the current working directory. You can specify a
different location by passing `--path /path/to/certs` to NervesHubCLI mix
commands.

NervesHub certificates and hardware identifiers are persisted to the firmware
when the firmware is burned to the SD card. To make this process easier, you can
call `nerves_hub.device burn IDENTIFIER`. In this example, we are going to burn
the firmware and certificates for device `1234` that we created.

```bash
mix nerves_hub.device burn 1234
```

Your device will now connect to NervesHub when it boots and establishes an
network connection.

### Creating deployments

Deployments associate firmware images to devices. NervesHub won't send firmware
to a device until you create a deployment. First find the UUID of the firmware.
You can list the firmware on NervesHub by calling:

```bash
mix nerves_hub.firmware list

Firmwares:
------------
  product:      example
  version:      0.3.0
  platform:     rpi3
  architecture: arm
  uuid:         1cbecdbb-aa7d-5aee-4ba2-864d518417df
```

In this example we will create a new deployment for our test group using firmware
`1cbecdbb-aa7d-5aee-4ba2-864d518417df`.

```bash
mix nerves_hub.deployment create

NervesHub org: nerveshub
Deployment name: qa_deployment
firmware uuid: 1cbecdbb-aa7d-5aee-4ba2-864d518417df
version condition:
tags: qa
Local user password:
Deployment test created
```

Here we create a new deployment called `qa_deployment`. In the conditions of this
deployment we left the `version condition` unspecified and the `tags` set to
only `qa`.  This means that in order for a device to qualify for an update, it
needs to have at least the tags `[qa]` and the device can be coming from any
version.

At this point we can try to update the connected device.

Start by bumping the application version number from `0.1.0` to `0.1.1`. Then,
create new firmware:

```bash
mix firmware
```

We can publish, sign, and deploy firmware in a single command now.

```bash
mix nerves_hub.firmware publish --key devkey --deploy qa_deployment
```
