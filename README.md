# EasyTier Docker

[![Release](https://github.com/HINS-Deployment/easytier-docker/actions/workflows/build-release.yml/badge.svg)](https://github.com/HINS-Deployment/easytier-docker/actions/workflows/build-release.yml)
[![Pre-release](https://github.com/HINS-Deployment/easytier-docker/actions/workflows/build-pre.yml/badge.svg)](https://github.com/HINS-Deployment/easytier-docker/actions/workflows/build-pre.yml)
[![CI](https://github.com/HINS-Deployment/easytier-docker/actions/workflows/build-ci.yml/badge.svg)](https://github.com/HINS-Deployment/easytier-docker/actions/workflows/build-ci.yml)

[EasyTier](https://github.com/EasyTier/EasyTier) 发布新版本时，自动构建并发布 Docker 镜像

## 镜像版本说明

本项目提供三种镜像变体，适用于不同的部署场景：

### 1. 混合版 (Core + Web)
- **标签**: `latest`, `<version>` (如 v2.4.5)
- **特点**: 同时包含 Core 和 Web 控制台，一站式解决方案
- **适用场景**: 个人用户、小型团队、单机部署
- **镜像**: `wuhins/easytier:latest`

### 2. 纯 Core 版
- **标签**: `core-latest`, `<version>-core` (如 v2.4.5-core)
- **特点**: 仅包含 EasyTier Core，需要连接到远程 Web 控制台
- **适用场景**: 多节点分布式部署、集中化管理
- **镜像**: `wuhins/easytier:core-latest`

### 3. 纯 Web 版
- **标签**: `web-latest`, `<version>-web` (如 v2.4.5-web)
- **特点**: 仅包含 Web 控制台，用于管理多个远程 Core 节点
- **适用场景**: 中央管理节点、控制面板独立部署
- **镜像**: `wuhins/easytier:web-latest`

### 版本渠道

- **Release (稳定版)**: `latest`, `core-latest`, `web-latest`, `<version>`, `<version>-core`, `<version>-web`
- **Pre-release (预览版)**: `pre`, `core-pre`, `web-pre`, `<version-number>`, `<version-number>-core`, `<version-number>-web`
- **CI (开发版)**: `ci`, `core-ci`, `web-ci` (自动更新，稳定性不保证)

## 部署场景示例

### 场景 1: 单机部署（混合版）
适合个人用户或小型团队，所有功能在一个容器中运行。

```bash
docker run -d \
  --name easytier \
  --restart always \
  --network host \
  --cap-add NET_ADMIN --cap-add NET_RAW \
  --device /dev/net/tun:/dev/net/tun \
  -v ./data:/app/data \
  -e TZ=Asia/Shanghai \
  -e WEB_ENABLE=true \
  -e WEB_USERNAME=admin \
  wuhins/easytier:latest
```

### 场景 2: 多节点集中管理（纯 Core + 纯 Web）
一个中央 Web 控制台管理多个 Core 节点。

**中央 Web 节点:**
```bash
docker run -d \
  --name easytier-web \
  --restart always \
  -p 11211:11211 \
  -p 22020:22020/udp \
  -v ./data-web:/app/data \
  -e TZ=Asia/Shanghai \
  -e WEB_PORT=11211 \
  -e WEB_SERVER_PORT=22020 \
  -e WEB_DEFAULT_API_HOST=http://your-server-ip:11211 \
  wuhins/easytier:web-latest
```

**Core 节点 1:**
```bash
docker run -d \
  --name easytier-core-node1 \
  --restart always \
  --network host \
  --cap-add NET_ADMIN --cap-add NET_RAW \
  --device /dev/net/tun:/dev/net/tun \
  -v ./data-core1:/app/data \
  -e TZ=Asia/Shanghai \
  -e HOSTNAME=node1 \
  -e WEB_REMOTE_API=udp://web-server-ip:22020/admin \
  wuhins/easytier:core-latest
```

**Core 节点 2:**
```bash
docker run -d \
  --name easytier-core-node2 \
  --restart always \
  --network host \
  --cap-add NET_ADMIN --cap-add NET_RAW \
  --device /dev/net/tun:/dev/net/tun \
  -v ./data-core2:/app/data \
  -e TZ=Asia/Shanghai \
  -e HOSTNAME=node2 \
  -e WEB_REMOTE_API=udp://web-server-ip:22020/admin \
  wuhins/easytier:core-latest
```

### 场景 3: Docker Compose 部署
查看 [compose/docker-compose.yaml](compose/docker-compose.yaml) 获取完整的 Compose 配置示例，包括三种场景的详细配置。

## Compose

<!-- BEGIN_COMPOSE_CORE -->
```yaml
# Core + Web 控制台一体部署
# 镜像说明: https://hub.docker.com/r/wuhins/easytier
services:
  easytier:
    # wuhins/easytier:latest  最新 Release 正式版
    # wuhins/easytier:pre     最新 Pre-release 预览版
    # wuhins/easytier:ci      最新 Action 构建版 (合并主线的版本, 自动更新, 稳定性不保证)
    image: wuhins/easytier:latest
    container_name: easytier
    restart: always
    # 限制容器输出日志的大小和数量, 建议启用
    logging:
      driver: "json-file"
      options:
        # 单个日志文件的最大大小  
        max-size: "10m"
        # 最多保留的日志文件数量
        max-file: "3"
    network_mode: host
    environment:
      - TZ=Asia/Shanghai
      # -------------------------------------------
      # 自定义节点主机名, 可用于 Web 控制台显示和区分不同节点
      # 默认: 无
      # - HOSTNAME=node1
      # -------------------------------------------
      # 连接其他远程 Web 控制台
      # 设置后会忽略 WEB_USERNAME, 不可同时连接多个 Web, 但仍可启用本地控制台
      # 示例: udp://api.web.com:22020/username
      # 默认: 无
      # - WEB_REMOTE_API=协议://主机:端口/用户名
      # -------------------------------------------
      # 是否启用 Web 管理界面 
      # 默认: false
      - WEB_ENABLE=false
      # -------------------------------------------
      # 是否允许注册新用户 (内置用户: admin, 密码: admin, 登录后右上角可修改密码)
      # 默认: false
      - WEB_ENABLE_REGISTRATION=false
      # -------------------------------------------
      # Web 管理用户名; 设置 WEB_REMOTE_API 时此项无效
      # 启用 Web 且提供用户名时将自动连接本地控制台
      # 自定义用户名，需要先手动注册对应用户名才行 
      # 默认: 无
      - WEB_USERNAME=admin
      # -------------------------------------------
      # 主机物理IP地址 (公网 / 内网)
      # 默认: http://127.0.0.1:11211
      - WEB_DEFAULT_API_HOST=http://修改为你的主机:11211
      # -------------------------------------------
      # Web 访问端口
      # 默认: 11211
      - WEB_PORT=11211
      # -------------------------------------------
      # Web 管理服务 (RPC) 监听端口, Core 将通过此端口连接
      # 默认: 22020
      - WEB_SERVER_PORT=22020
      # -------------------------------------------
      # Web 管理服务 (RPC) 协议, 可与其他节点的 -w 参数保持一致
      # 默认: udp - 可选: [udp | tcp | ws]
      - WEB_SERVER_PROTOCOL=udp
      # -------------------------------------------
      # Web 服务日志级别 
      # 默认: error - 可选: [off | error | warn | info | debug | trace] 
      - WEB_LOG_LEVEL=error
      # -------------------------------------------
      # Core 服务日志级别
      # 默认: error - 可选: [ error | warn | info | debug | trace]
      - CORE_LOG_LEVEL=error
      # -------------------------------------------
      # GeoIP 数据库文件路径 (可在 Web 控制台显示地理位置信息)
      # 推荐: https://github.com/P3TERX/GeoLite.mmdb/releases (建议放到放到映射的目录 ./data/web 下, 记得更改对应文件名称/路径)
      # 默认: 无
      # - WEB_GEOIP_PATH=/app/data/web/GeoLite2-City.mmdb
      # -------------------------------------------
      # 允许为未知的心跳 Token 自动创建本地用户
      # 默认: false
      # - ALLOW_AUTO_CREATE_USER=false
      # -------------------------------------------
      # OIDC 单点登录配置 (用于对接 Keycloak, Authentik, Okta, Azure AD 等身份提供商)
      # OIDC 发行者 URL, 用于自动发现配置, 示例: https://auth.example.com/realms/myrealm
      # 默认: 无
      # - OIDC_ISSUER_URL=
      # OIDC 客户端 ID
      # 默认: 无
      # - OIDC_CLIENT_ID=
      # OIDC 客户端密钥 (推荐使用环境变量而非命令行传递)
      # 默认: 无
      # - OIDC_CLIENT_SECRET=
      # OIDC 回调 URL, 必须与 IdP 配置完全一致, 示例: https://easytier.example.com/api/v1/auth/oidc/callback
      # 默认: 无
      # - OIDC_REDIRECT_URL=
      # 用于提取用户名的 Claim, 默认: preferred_username
      # 默认: preferred_username
      # - OIDC_USERNAME_CLAIM=preferred_username
      # 请求的权限范围, 默认: openid,profile
      # 默认: openid,profile
      # - OIDC_SCOPES=openid,profile
      # 为不支持 PKCE 的旧版 IdP 禁用 PKCE
      # 默认: false
      # - OIDC_DISABLE_PKCE=false
      # 前后端分离部署模式下的前端基础 URL, 示例: https://easytier.example.com
      # 默认: 无 (使用相对路径)
      # - OIDC_FRONTEND_BASE_URL=
    cap_add:
      - NET_ADMIN
      - NET_RAW
    devices:
      - /dev/net/tun:/dev/net/tun
    volumes:
      - ./data:/app/data
      # 将写好的配置文件放在 ./data/config 下每个文件都是一个实例(.toml格式), 会跟着容器一起启动/运行
```
<!-- END_COMPOSE_CORE -->
