# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: miparis <miparis@student.42madrid.com>     +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/10/28 19:39:45 by miparis           #+#    #+#              #
#    Updated: 2026/11/06 17:54:31 by miparis          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME = inception
COMPOSE = srcs/docker-compose.yml
DATA_DIR = /home/miparis/data

# Define Colors
GREEN  := \033[1;32m  # Bold Green
YELLOW := \033[0;33m  # Non-bold Yellow
RED    := \033[0;31m  # Regular Red
BLUE   := \033[1;34m  # Bold Blue
PURPLE := \033[1;35m  # Bold Purple
BOLD   := \033[1m     # Bold Text
NC     := \033[0m     # No Color (Resets color and style)

all: up

up:
	@echo "$(BOLD)$(BLUE)🚀 Creating Inception infraestructure...$(NC)"
	@docker-compose -f $(COMPOSE) up -d --build
	@echo "$(BOLD)$(GREEN)✅ Conteiners build and on execution$(NC)"

down:
	@echo "$(BOLD)$(YELLOW)🛑 Stopping containers...$(NC)"
	@docker-compose -f $(COMPOSE) down
	@echo "$(BOLD)$(GREEN)✅ Containers stopped correctly$(NC)"

clean:
	@echo "$(BOLD)$(RED)🗑️ Deleting containers, networks and images...$(NC)"
	@docker-compose -f $(COMPOSE) down -v --rmi all
	@echo "$(BOLD)$(GREEN)🧹 Basic cleaning completed$(NC)"

volumes:
	mkdir -p /home/miparis/data/mariadb
	mkdir -p /home/miparis/data/wordpress

fclean: clean
	@echo "$(BOLD)$(PURPLE)☢️ Executing deep cleaning (deleting local data)...$(NC)"
	@sudo rm -rf $(DATA_DIR)/mariadb/*
	@sudo rm -rf $(DATA_DIR)/wordpress/*
	@docker system prune -af
	@echo "$(BOLD)$(GREEN)🧹 Full cleaning completed$(NC)"

re: fclean all

clear:
	@clear

.PHONY: all up down clean fclean re clear