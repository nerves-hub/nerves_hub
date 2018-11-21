# Setting up a local development environment

Setup local env vars

```
export NERVES_HUB_HOME=./nerves-hub
export NERVES_HUB_HOST=0.0.0.0
export NERVES_HUB_PORT=4002
export NERVES_HUB_CA_DIR=/absolute/path/to/nerves_hub_web/test/fixtures/ssl/
```

Setup a local instance of Nerves Hub CA

```bash
git clone git@github.com:nerves-hub/nerves_hub_ca.git
cd nerves_hub_ca
source dev.env
mix do deps.get, nerves_hub_ca.init, ecto.create, ecto.migrate
iex -S mix
```

Setup a local instance of Nerves Hub

```bash
git clone git@github.com:nerves-hub/nerves_hub_web.git
cd nerves_hub_web
mix deps.get
docker-compose up -d
make reset-db
make server
```

Setup a local instance of NervesHub

```bash
git clone git@github.com:nerves-hub/nerves_hub.git
cd nerves_hub
mix deps.get
mix nerves_hub.user register # use test@test.org for good luck.
mix nerves_hub.product create --name test
mix nerves_hub.device cert create test
mix deps.compile --force # this is to reload cert and key you just created
iex -S mix # make your changes, test em out etc.
```