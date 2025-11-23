# frp一键部署
frps一键部署并设置开机自启
安装命令：
```
curl -sSL https://github.com/eljefeZZZ/frp-/raw/refs/heads/main/install_frp_server.sh | tr -d '\r' > install.sh && chmod +x install.sh && ./install.sh
```
卸载命令：
```
curl -sSL https://raw.githubusercontent.com/eljefeZZZ/frp-/refs/heads/main/uninstall_frp.sh | bash
