#!/bin/bash

# ╔══════════════════════════════╗
# ║     tawanaproxy installer   ║
# ║     Author: @tawanaproxy    ║
# ╚══════════════════════════════╝

set -e

# 🎨 رنگ‌ها
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

print_line() {
  echo -e "${CYAN}=========================================${RESET}"
}

echo -e "${GREEN}🚀 Welcome to tawanaproxy – HAProxy TLS Router Auto Installer${RESET}"
print_line

# نصب HAProxy اگر موجود نبود
if ! command -v haproxy >/dev/null 2>&1; then
  echo -e "${YELLOW}[+] Installing HAProxy...${RESET}"
  apt update -y && apt install -y haproxy
else
  echo -e "${GREEN}[✓] HAProxy already installed${RESET}"
fi
print_line

# گرفتن ورودی‌های کاربر
read -p "📥 Panel domain (e.g. nesh.example.ir): " DOMAIN_PANEL
read -p "📥 VLESS+WS domain: " DOMAIN_WS
read -p "📥 VMESS+TCP domain: " DOMAIN_TCP
read -p "📥 XHTTP domain (e.g. for Trojan): " DOMAIN_XHTTP
read -p "📥 Hysteria domain: " DOMAIN_HYSTERIA
read -p "📥 Reality domain: " DOMAIN_REALITY

read -p "📍 Local port for panel [8000]: " PORT_PANEL
PORT_PANEL=${PORT_PANEL:-8000}
read -p "📍 Port for VLESS+WS [1001]: " PORT_WS
PORT_WS=${PORT_WS:-1001}
read -p "📍 Port for VMESS+TCP [1002]: " PORT_TCP
PORT_TCP=${PORT_TCP:-1002}
read -p "📍 Port for XHTTP [1003]: " PORT_XHTTP
PORT_XHTTP=${PORT_XHTTP:-1003}
read -p "📍 Port for Hysteria [1004]: " PORT_HYSTERIA
PORT_HYSTERIA=${PORT_HYSTERIA:-1004}
read -p "📍 Port for Reality [1005]: " PORT_REALITY
PORT_REALITY=${PORT_REALITY:-1005}
print_line

echo -e "${YELLOW}[+] Generating HAProxy config at /etc/haproxy/haproxy.cfg...${RESET}"

cat <<EOF > /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    daemon
    maxconn 2048
    tune.ssl.default-dh-param 2048

defaults
    log     global
    mode    tcp
    option  tcplog
    timeout connect 10s
    timeout client  1m
    timeout server  1m

frontend fe_tls
    bind *:443
    mode tcp
    tcp-request inspect-delay 5s
    tcp-request content accept if { req.ssl_hello_type 1 }

    use_backend be_panel    if { req.ssl_sni -i ${DOMAIN_PANEL} }
    use_backend be_ws       if { req.ssl_sni -i ${DOMAIN_WS} }
    use_backend be_tcp      if { req.ssl_sni -i ${DOMAIN_TCP} }
    use_backend be_xhttp    if { req.ssl_sni -i ${DOMAIN_XHTTP} }
    use_backend be_hysteria if { req.ssl_sni -i ${DOMAIN_HYSTERIA} }
    use_backend be_reality  if { req.ssl_sni -i ${DOMAIN_REALITY} }

    default_backend be_panel

backend be_panel
    mode tcp
    server panel 127.0.0.1:${PORT_PANEL} check

backend be_ws
    mode tcp
    server ws 127.0.0.1:${PORT_WS} check

backend be_tcp
    mode tcp
    server tcp 127.0.0.1:${PORT_TCP} check

backend be_xhttp
    mode tcp
    server xhttp 127.0.0.1:${PORT_XHTTP} check

backend be_hysteria
    mode tcp
    server hysteria 127.0.0.1:${PORT_HYSTERIA} check

backend be_reality
    mode tcp
    server reality 127.0.0.1:${PORT_REALITY} check
EOF

print_line
echo -e "${YELLOW}[+] Restarting HAProxy service...${RESET}"
systemctl restart haproxy
systemctl enable haproxy

print_line
echo -e "${GREEN}✅ tawanaproxy is now installed and configured!${RESET}"
echo -e "${CYAN}➡️  Config file: /etc/haproxy/haproxy.cfg${RESET}"
print_line
