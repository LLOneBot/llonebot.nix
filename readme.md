# 参考

[chronocat.nix](https://github.com/Anillc/chronocat.nix) 若有侵权，请联系我删除


# 使用方法

## docker

### docker compose

```yaml
version: "3"
services:
    llonebot:
        volumes:
            - ./QQ:/root/.config/QQ # 挂载 QQ 配置目录
            - ./llonebot:/root/llonebot # 挂载 llonebot 数据目录
        ports:
            - 3000:3000 # OneBot HTTP 端口
            - 3001:3001 # OneBot WebSocket 端口
            - 5600:5600 # Satori 端口
            - 3080:3080 # webui
        container_name: llonebot
        network_mode: bridge
        restart: always
        image: initialencounter/llonebot:latest
```

### docker cli

```bash
docker run -d \
  --name llonebot \
  -p 3000:3000 \
  -p 3001:3001 \
  -p 5600:5600 \
  -p 3080:3080 \
  -v ./QQ:/root/.config/QQ \
  -v ./llonebot:/root/llonebot \
  --restart unless-stopped \
  initialencounter/llonebot:latest
```

## 接入 qq-ai-bot（可选）

如果你想把 LLOneBot 作为 **QQ ↔ AI** 链路的协议侧，可以直接接一个现成的 `qq-ai-bot`：

完整 compose 示例见：[examples/qq-ai-bot-compose.yml](./examples/qq-ai-bot-compose.yml)

```yaml
version: "3"
services:
  llonebot:
    image: initialencounter/llonebot:latest
    container_name: llonebot
    restart: always
    ports:
      - 3001:3001
      - 3080:3080
    volumes:
      - ./QQ:/root/.config/QQ
      - ./llonebot:/root/llonebot
    networks:
      - qq_ai_bot

  qq-ai-bot:
    image: ghcr.io/happysnaker/qq-ai-bot:latest
    container_name: qq-ai-bot
    restart: always
    environment:
      - BOT_PORT=8080
      - DATA_DIR=/app/data
      - SESSION_FILE_PATH=/app/data/sessions.json
      - ONEBOT_MODE=forward
      - ONEBOT_FORWARD_WS_URL=${ONEBOT_FORWARD_WS_URL}
      - ONEBOT_ACCESS_TOKEN=llonebot-shared-token
      - ONEBOT_ALLOW_GROUP=true
      - ONEBOT_REQUIRE_MENTION_IN_GROUP=true
      - ONEBOT_ALLOW_PRIVATE=true
      - ONEBOT_PROGRESS_MODE=message
      - ACP_AGENT_COMMAND=node
      - 'ACP_AGENT_ARGS_JSON=["dist/examples/mock-acp-agent.js"]'
      - ACP_AGENT_WORKDIR=/app
      - ACP_REUSE_SESSION=true
      - ACP_VERBOSE_MODE=verbose
    ports:
      - 18080:8080
    volumes:
      - ./qq-ai-bot/data:/app/data
    networks:
      - qq_ai_bot

networks:
  qq_ai_bot:
    driver: bridge
```

然后在 LLOneBot 的 OneBot11 配置里启用一个 **正向 WS**：

```json5
{
  "type": "ws",
  "enable": true,
  "host": "0.0.0.0",
  "port": 3001,
  "token": "llonebot-shared-token",
  "messageFormat": "array",
  "reportSelfMessage": false
}
```

如果你是在 **Docker 私有桥接网络** 内直接把两个容器互连，`ONEBOT_FORWARD_WS_URL` 可以填容器内网地址；如果你是跨主机、跨网络段，或者需要经过公网 / 反向代理，请改成带 TLS 的 `wss://...` 地址。

注意：`qq-ai-bot` 里的 `ONEBOT_ACCESS_TOKEN` 必须和 LLOneBot OneBot11 配置里的 `token` 保持一致。

- 项目地址：<https://github.com/happysnaker/qq-ai-bot>
- 项目页：<https://happysnaker.github.io/qq-ai-bot/>

## 快速体验

```bash
# 沙盒运行
nix run github:LLOneBot/llonebot.nix#sandbox

# 直接在桌面运行（需要桌面环境）
nix run github:LLOneBot/llonebot.nix

# 仅运行 pmhq
nix run github:LLOneBot/llonebot.nix#pmhq
```

## NixOS 配置

无需桌面环境
[sandbox](./examples/sandbox.nix)

需要桌面环境版
[desktop](./examples/sandbox.nix)

## 登录

- 终端扫码
- WebUI http://<宿主机IP>:3080 扫码

## 配置自动登录QQ号

- 设置环境变量 QUICK_LOGIN_QQ
