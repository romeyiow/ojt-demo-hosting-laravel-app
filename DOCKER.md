# Docker Setup Guide

This project uses **Laravel Sail** for containerized local development.

## Prerequisites

- Docker (or Docker Desktop) and Docker Compose installed
- Docker daemon running

## Quick Start

### 1. First-Time Setup

```bash
# Install PHP dependencies
composer install

# Build and start containers (will download/build images on first run)
./vendor/bin/sail up -d

# Run migrations
./vendor/bin/sail artisan migrate

# Install Node dependencies and build frontend
./vendor/bin/sail npm install
./vendor/bin/sail npm run build

# Generate app key (if not already set)
./vendor/bin/sail artisan key:generate
```

### 2. Daily Workflow

```bash
# Start containers
./vendor/bin/sail up -d

# Run artisan commands
./vendor/bin/sail artisan tinker
./vendor/bin/sail artisan queue:work

# Run npm/build commands
./vendor/bin/sail npm run dev

# Run tests
./vendor/bin/sail artisan test

# Stop containers
./vendor/bin/sail down
```

### 3. Shell Access

```bash
# Interactive Bash shell in app container
./vendor/bin/sail shell

# Root shell (for permission issues)
./vendor/bin/sail root-shell

# Laravel Tinker REPL
./vendor/bin/sail tinker
```

## Shell Alias (Optional)

Add to your `~/.bashrc` or `~/.zshrc` for shorter commands:

```bash
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
```

Then use:
```bash
sail up -d
sail artisan migrate
sail npm run dev
```

## Database

- **Driver:** SQLite
- **File:** `database/database.sqlite` (auto-created inside container)
- **Tests:** SQLite in-memory (`:memory:`) via phpunit.xml

## Frontend Development

Vite runs inside the container on port 5173:

```bash
./vendor/bin/sail npm run dev
```

Open http://localhost:5173 in your browser (Vite HMR enabled).

## Troubleshooting

### Docker/Container Issues

**"Docker is not running"**
- Start Docker Desktop or `sudo systemctl start docker` on Linux

**"Permission denied" on Linux**
- Run `docker context use default` if using custom context
- May need to set `SUPERVISOR_PHP_USER=root` in `.env`

**Slow file watching on Linux (Vite)**
- Docker file watching can be slow on Linux with bind mounts
- Consider using Docker Desktop's VirtioFS or WSL2 on Windows

### Database Issues

**"database.sqlite not found"**
- Database is auto-created on first migration
- Ensure `database/` folder exists: `mkdir -p database`

**"SQLSTATE[HY000]: General error: 14 unable to open database file"**
- Check that `database/` folder is writable inside container
- Run: `./vendor/bin/sail artisan tinker` and execute: `Schema::createDatabase('sqlite');`

### Other

**Rebuild images after composer/package changes**
```bash
./vendor/bin/sail down -v
./vendor/bin/sail build --no-cache
./vendor/bin/sail up -d
```

**View Sail logs**
```bash
./vendor/bin/sail logs -f
```

**Customize Sail configuration**
```bash
./vendor/bin/sail artisan sail:publish
# Then edit docker/ directory and rebuild
```

## References

- [Laravel Sail Documentation](https://laravel.com/docs/sailing)
- [Docker Compose Reference](https://docs.docker.com/compose/reference/)
