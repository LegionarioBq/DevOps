# DevOps
Artigos e Scripts


# 🚀 Script de Instalação da Base com Docker

Este script automatiza a configuração inicial de um servidor Ubuntu Server 24.04 LTS, incluindo:

- Atualização completa do sistema
- Definição do fuso horário (America/Sao_Paulo)
- Instalação da versão mais recente do Docker e dependências
- Habilitação dos serviços Docker e containerd para inicialização automática

---

## 📂 Arquivo

**Nome do script:** `instalar_base_loadbalance.sh`

---

## ✅ Requisitos

- Ubuntu Server 24.04 LTS (ou versões compatíveis)
- Permissões de superusuário (`sudo`)

---

## 🔧 Execução

### ▶️ 1. Executar **remotamente via `curl`** (sem baixar o arquivo)

Suba o script no seu GitHub e execute diretamente com:

```bash
curl -sSL https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/instalar_base_loadbalance.sh | bash

