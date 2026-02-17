#!/bin/bash
set -e

# Source the .env file if it exists
if [ -f .env ]; then
  export $(cat .env | xargs)
fi
export DATABASE_URL="postgresql://dev_user:dev_password@db:15432/dev_db"


echo "Starting entrypoint script..."
echo "DATABASE_URL: $DATABASE_URL"

# Wait for the database to be ready
while ! pg_isready -h db -p 15432 -q -U dev_user; do
  echo "Waiting for database connection..."
  sleep 2
done

echo "Database is ready."
echo "Creating database..."
mix ecto.create
# Run migrations
echo "Running migrations..."
mix ecto.migrate

# Run seeds if the SEED_DB environment variable is set to true
if [ "$SEED_DB" = "true" ]; then
  echo "Seeding database..."
  mix run priv/repo/seeds.exs
fi

echo "Starting Phoenix app..."
# Start the Phoenix app
exec mix "$@"