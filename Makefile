COMPOSE := docker compose -f srcs/docker-compose.yml
DATA_ROOT := /home/abougati/data
DATA_DIRS := $(DATA_ROOT)/mariadb $(DATA_ROOT)/wordpress
SECRET_FILES := db_password.txt db_root_password.txt wp_admin_password.txt wp_user_password.txt

.DEFAULT_GOAL := all

.PHONY: all setup secrets build up down stop start logs ps clean re

all: setup secrets up

setup:
	@mkdir -p secrets
	@if [ -d $(DATA_ROOT)/mariadb ] && [ -d $(DATA_ROOT)/wordpress ]; then \
		:; \
	elif mkdir -p $(DATA_DIRS) 2>/dev/null && chmod 0750 $(DATA_DIRS) 2>/dev/null; then \
		:; \
	else \
		printf '%s\n' 'Creating $(DATA_DIRS) requires administrator privileges.'; \
		sudo install -d -m 0750 -o "$$USER" -g "$$USER" $(DATA_DIRS); \
	fi

secrets:
	@set -eu; for name in $(SECRET_FILES); do \
		path="secrets/$$name"; \
		if [ ! -s "$$path" ]; then \
			printf 'Error: missing secret: %s\n' "$$path" >&2; \
			exit 1; \
		fi; \
		chmod 0600 "$$path"; \
	done

build: setup secrets
	$(COMPOSE) build

up: setup secrets
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down --remove-orphans

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down --rmi all --remove-orphans

re: clean all
