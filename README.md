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
      {:nerves_runtime, "~> 0.4"},
      {:nerves_init_gadget, "~> 0.1"},
      {:nerves_time, "~> 0.2"},
      {:nerves_hub, path: "~> 0.1"}
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

### Setting up the CLI

The [NervesHubCLI](https://github.com/nerves-hub/nerves_hub_cli) is included as
a dependency of `nerves_hub`. Since `nerves_hub` is only a target dependency,
you can only run `nerves_hub` mix tasks when the target is set. To make it
always available, add  `nerves_hub_cli` to all deps:

```elixir
  defp deps do
    [
      {:nerves, "~> 1.3", runtime: false},
      {:nerves_hub_cli, "~> 0.1", runtime: false},
      {:shoehorn, "~> 0.3"}
    ] ++ deps(@target)
  end
```

Using the NervesHubCLI requires that you first create a NervesHub account and
create your user certificates. You can register for a new account by running:

```bash
mix nerves_hub.user register
```

If you have an existing account, you can authenticate by running:

```bash
mix nerves_hub.user auth
```

### Creating a NervesHub product

NervesHub products are a way of grouping devices running firmware that is
created from your source mix project. NervesHub uses the :app name in your
mix.exs for the project name. If you would like it to use a different name, add
a :name field to your Mix.Project.config(). For example, NervesHub would use "My
Example" instead of "example" for the following project.

```elixir
  def project do
    [
      app: :example,
      name: "My Example"
    ]
  end
```

For the remainder of this document, we will be using the product name `example`.

You can create a new product on nerves hub by running:

```bash
mix nerves_hub.product create --name example
```

### Creating NervesHub firmware signing keys

In order to publish and distribute firmware using NervesHub, your firmware needs
to be signed. Firmware signing keys consist of a public / private key pair that
that is generated on your computer. Only the public key is shared with NervesHub
and is used to verify the origination of the signed firmware bundle. In this
example we are going to create a `test` key, and instruct our app to trust it.

First start by generating a new key pair.

```bash
mix nerves_hub.key create test
```

NervesHub needs to know which keys your application trusts. Key names are
specified in your `config.exs`.

```elixir
config :nerves_hub,
  public_keys: [:test]
```

You can have multiple key names specified in this list. When the `nerves_hub`
dependency is compiled, it will replace the key names in this list with the
local public key contents from the NervesHubCLI key storage. It is recommended
to recompile `nerves_hub` after modifying this list.

You can recompile `nerves_hub` by running:

```bash
mix deps.compile nerves_hub --force
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
mix nerves_hub.firmware sign
```

Firmware can also be signed while publishing:

```bash
mix nerves_hub.firmware publish --key test
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
tags: test
Local user password:
Deployment test created
```

Here we create a new deployment called `test`. In the conditions of this
deployment we left the `version condition` unspecified and the `tags` set to
only `test`.  This means that in order for a device to qualify for an update, it
needs to have at least the tags `[test]` and the device can be coming from any
version.

At this point we can try to update the connected device.

Start by bumping the application version number from `0.1.0` to `0.1.1`. Then,
create new firmware:

```bash
mix firmware
```

We can publish, sign, and deploy firmware in a single command now.

```bash
mix nerves_hub.firmware publish --key test --deploy test
```
