#!/bin/bash
# ==========================================================
# Script: Instalar e atualizar Docker (WSL2 + Ubuntu com systemd nativo)
# Autor: Albert Andrade
# Atualizado em: 05/10/2025
# ==========================================================

echo "🕒 Atualizando data e fuso horário..."
date
sudo timedatectl set-timezone America/Sao_Paulo
timedatectl
date

echo "🛠️ Atualizando sistema..."
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean

# ===== Ativar systemd no WSL2 =====
if ! grep -q "systemd=true" /etc/wsl.conf 2>/dev/null; then
    echo "⚙️ Ativando systemd no WSL2..."
    sudo bash -c 'cat > /etc/wsl.conf <<EOF
[boot]
systemd=true
EOF'
    echo "⚠️ Systemd ativado. Execute o comando abaixo no PowerShell e reabra o Ubuntu:"
    echo "    wsl --shutdown"
    exit 0
fi

# ===== Remover instalações antigas de Docker =====
echo "🧹 Removendo versões antigas do Docker (se existirem)..."
sudo apt remove -y docker docker-engine docker.io containerd runc
sudo rm -rf /var/lib/docker /var/lib/containerd
sudo apt update

# ===== Instalar dependências do Docker =====
echo "📦 Instalando dependências e repositórios oficiais do Docker..."
sudo apt install -y ca-certificates curl gnupg lsb-release apt-transport-https software-properties-common

# Adicionar chave GPG do Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg

# Adicionar repositório estável
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Atualizar repositórios
sudo apt update

# ===== Instalar Docker Engine completo =====
echo "🐳 Instalando Docker Engine nativo (com Buildx e Compose plugin)..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ===== Criar configuração do daemon =====
echo "⚙️ Configurando daemon do Docker..."
sudo mkdir -p /etc/docker
echo '{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" },
  "storage-driver": "overlay2"
}' | sudo tee /etc/docker/daemon.json > /dev/null

# ===== Habilitar e iniciar serviços =====
echo "🚀 Habilitando e iniciando serviços..."
sudo systemctl enable docker
sudo systemctl enable containerd
sudo systemctl start docker

# ===== Testar instalação =====
echo "🔍 Testando instalação do Docker..."
if sudo docker run --rm hello-world; then
    echo "✅ Docker Engine instalado e funcionando corretamente!"
else
    echo "❌ Erro: Docker não inicializou corretamente. Verifique com: sudo systemctl status docker"
fi

# ===== Instalar Docker Compose standalone (backup) =====
if ! command -v docker-compose &> /dev/null; then
    echo "📦 Instalando Docker Compose standalone (fallback)..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose instalado:"
    docker-compose --version
else
    echo "📦 Docker Compose já está instalado:"
    docker-compose --version
fi

# ===== Permitir uso sem sudo =====
if ! groups $USER | grep -q "\bdocker\b"; then
    echo "👤 Adicionando usuário '$USER' ao grupo docker..."
    sudo usermod -aG docker $USER
    echo "⚠️ Saia e entre novamente no WSL para aplicar a permissão!"
fi

# ===== Geração de chave SSH opcional =====
echo ""
read -p "🔐 Deseja gerar uma chave SSH RSA 2048 bits para usar em seu servidor no CI/CD? (s/n): " resposta < /dev/tty

if [[ "$resposta" =~ ^[Ss]$ ]]; then
    if ! command -v ssh-keygen &> /dev/null; then
        echo "❌ Comando 'ssh-keygen' não encontrado. Instale o pacote openssh-client e tente novamente."
        exit 1
    fi

    SSH_DIR="$HOME/.ssh"
    KEY_NAME="id_rsa_ci_cd"

    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    if [[ -f "$SSH_DIR/$KEY_NAME" ]]; then
        read -p "⚠️ A chave '$KEY_NAME' já existe. Deseja sobrescrever? (s/n): " overwrite < /dev/tty
        [[ ! "$overwrite" =~ ^[Ss]$ ]] && echo "❌ Operação cancelada." && exit 0
    fi

    ssh-keygen -t rsa -b 2048 -f "$SSH_DIR/$KEY_NAME" -N "" -C "$USER@$(hostname)"
    chmod 600 "$SSH_DIR/$KEY_NAME"

    echo ""
    echo "🟢 Chave pública gerada com sucesso:"
    cat "$SSH_DIR/$KEY_NAME.pub"
    echo ""
    echo "🛑 Chave privada (guarde com segurança!):"
    cat "$SSH_DIR/$KEY_NAME"
    echo ""
    echo "✅ Chave SSH salva em: $SSH_DIR/$KEY_NAME e $KEY_NAME.pub"
else
    echo "❌ Geração da chave SSH cancelada."
fi
