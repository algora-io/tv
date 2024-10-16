#!/bin/bash

# Wait for Postgres to become available
until psql $DATABASE_URL -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"

# Run migrations
mix ecto.setup

# Start the Phoenix app
mix phx.server