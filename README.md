# RoR-and-Tools-Test

Minimal Rails API project in Dev Containers.

Technical stack:
- Ruby on Rails 8 (API only)
- PostgreSQL
- Redis
- RSpec + FactoryBot

## 1. Open in Dev Container

In VS Code run:

1. `Dev Containers: Rebuild and Reopen in Container`

The workspace is mounted to `/workspace`.

## 2. Create Rails API app (inside container)

Run in terminal:

```bash
gem install rails -v '~> 8.0'
rails new . --api -d postgresql
bundle add redis
bundle add rspec-rails --group "development,test"
bundle add factory_bot_rails --group "development,test"
bin/rails generate rspec:install
```

## 3. Configure database and Redis

Create DB:

```bash
bin/rails db:create
bin/rails db:migrate
```

`DATABASE_URL` and `REDIS_URL` are already provided by `.devcontainer/docker-compose.yml`.

## 4. Start Rails API

```bash
bin/rails server -b 0.0.0.0 -p 3000
```

App will be available on `http://localhost:3000`.