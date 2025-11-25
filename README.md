# frp一键部署
代码完全由Gmini3 Pro编写，本人没有任何编程基础，上传目的是为了自己以后使用方便，仅在自己的两个机器上跑通了系统是Debian 9 x86_64  
，仅供新手参考！！！
# 🚀 FRP Server Auto Installer | frp 服务端一键部署脚本
---
![GitHub](https://img.shields.io/badge/License-MIT-green.svg) ![Shell](https://img.shields.io/badge/Language-Shell-blue.svg) ![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)
---
> **全自动部署、可视化管理、智能防火墙配置。让内网穿透变得前所未有的简单。**

本脚本旨在为 Linux VPS 用户提供最快捷的 `frps`（frp 服务端）部署方案。无需繁琐的手动编辑配置文件，只需一行命令，即可完成下载、安装、配置、开机自启及防火墙设置。

---

## ✨ 核心特性

- **⚡️ 极速安装**：自动获取 GitHub 最新版 frp，秒级部署。
- **🛠 可视化管理**：内置强大的管理面板，随时修改端口、Token、密码，重启或卸载。
- **🛡 智能防火墙**：自动检测 `ufw`、`firewalld` 或 `iptables`，自动放行所需端口。
- **🔐 安全可靠**：Token 和密码均支持随机生成，不硬编码任何敏感信息。
- **🤖 交互式配置**：全程向导式安装，小白也能轻松上手。
- **📊 信息汇总**：安装完成后自动展示所有连接信息（IP、端口、密钥），方便截图保存。

---

## 📥 一键安装 / 管理

无论你是**初次安装**，还是**后期管理**（修改配置/卸载），都只需要执行这一条命令：

```bash
curl -sSL https://github.com/eljefeZZZ/frp-/raw/refs/heads/main/install_frp_server.sh | tr -d '\r' > frp.sh && chmod +x frp.sh && ./frp.sh

---

> **提示**：脚本需要 `root` 权限运行。如果不是 root 用户，请先执行 `sudo -i` 切换。

---

## 📖 使用教程

### 1. 初次安装
运行上述命令后，脚本会引导你设置以下参数（直接回车可使用默认值）：

| 参数名称 | 默认值 | 说明 |
| :--- | :--- | :--- |
| **绑定端口 (Bind Port)** | `7000` | frp 客户端与服务端通信的端口 |
| **HTTP 端口** | `8080` | 用于 HTTP 穿透访问的端口 |
| **HTTPS 端口** | `8443` | 用于 HTTPS 穿透访问的端口 |
| **面板端口** | `7500` | 服务端 Web 管理后台端口 |
| **面板账号** | `admin` | 管理后台用户名 |
| **面板密码** | (必填) | 管理后台密码 |
| **Token** | (随机) | 客户端连接时的身份验证密钥 |

安装完成后，脚本会输出一个绿色的汇总面板，**请务必截图保存**。

### 2. 后期管理
再次运行一键命令，脚本会自动识别已安装状态，并弹出管理菜单：

=== frp 服务端一键管理脚本 ===

查看当前配置信息

修改绑定端口 (Bind Port)

修改 HTTP 端口

修改 HTTPS 端口

修改 Token (连接密钥)

修改 Dashboard 密码

重启 frps 服务

停止 frps 服务

卸载 frps

手动放行其他端口 (如 6001)

退出

text

---

## 📂 目录说明

脚本默认将 frp 安装在以下路径：
- **安装目录**: `/frp`
- **配置文件**: `/frp/frps.ini`
- **服务文件**: `/etc/systemd/system/frps.service`

---

## ❓ 常见问题 (FAQ)

**Q: 安装后客户端连不上，提示 `i/o timeout`？**  
A: 这通常是防火墙问题。脚本会自动放行基础端口，但如果你使用了自定义端口，请运行脚本选择菜单 **10. 手动放行其他端口**。另外，请检查云服务商（如 AWS/阿里云/腾讯云）的网页后台安全组是否放行了对应端口。

**Q: 为什么脚本显示的 IP 不是我的公网 IP？**  
A: 脚本会自动尝试获取公网 IPv4。如果你的 VPS 是纯 IPv6 环境或网络特殊，可能需要手动确认 IP。

**Q: 如何卸载？**  
A: 再次运行脚本，选择菜单 **9. 卸载 frps**，脚本会彻底清理所有文件和服务，不留残留。
---
*Created by [eljefeZZZ](https://github.com/eljefeZZZ)*
