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

echo ""
read -p "🔐 Deseja gerar uma chave SSH RSA 2048 bits para usar em seu servidor no CI/CD? (s/n): " resposta < /dev/tty

if [[ "$resposta" =~ ^[Ss]$ ]]; then
    if ! command -v ssh-keygen &> /dev/null; then
        echo "❌ Comando 'ssh-keygen' não encontrado. Instale o pacote openssh-client e tente novamente."
        exit 1
    fi

    SSH_DIR="$HOME/.ssh"
    KEY_NAME="id_rsa_ci_cd"

    # Cria o diretório .ssh se não existir
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    # Gera a chave SSH RSA 2048 bits
    ssh-keygen -t rsa -b 2048 -f "$SSH_DIR/$KEY_NAME" -N "" -C "$USER@$(hostname)"
    chmod 600 "$SSH_DIR/$KEY_NAME"

    echo ""
    echo "🟢 Chave pública gerada com sucesso:"
    echo "------------------------------------"
    cat "$SSH_DIR/$KEY_NAME.pub"

    echo ""
    echo "🛑 Chave privada (guarde com segurança!):"
    echo "----------------------------------------"
    cat "$SSH_DIR/$KEY_NAME"

    echo ""
    echo "✅ Chave SSH salva em: $SSH_DIR/$KEY_NAME e $KEY_NAME.pub"
else
    echo "❌ Geração da chave SSH cancelada."
fi
