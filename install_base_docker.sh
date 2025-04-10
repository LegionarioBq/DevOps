#!/bin/bash

# Script Instalar e atualizar base load balance

echo "🕒 Atualizando data e fuso horário..."
date
sudo timedatectl set-timezone America/Sao_Paulo
timedatectl
date

echo "🛠️ Atualizando sistema..."
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean

# Verifica se o Docker já está instalado
if command -v docker &> /dev/null
then
    echo "🐳 Docker já está instalado."
    docker --version
else
    echo "🐳 Instalando Docker (última versão)..."
    sudo apt install -y ca-certificates curl gnupg lsb-release

    # Adicionando chave oficial do Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg

    # Adicionando repositório oficial Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Atualizando e instalando Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Habilita e inicia o serviço Docker e containerd para iniciar automaticamente com o sistema
    sudo systemctl enable docker
    sudo systemctl enable containerd
    sudo systemctl start docker

    echo "✅ Docker instalado com sucesso!"
    docker --version
fi
