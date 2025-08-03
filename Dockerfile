# ---- 第 1 阶段：构建项目 ----
FROM node:22-slim AS builder

WORKDIR /app

# 复制依赖清单
COPY package.json package-lock.json ./

# 安装所有依赖（包括 devDependencies，构建需要）
RUN npm ci

# 复制全部源代码
COPY . .

# 在构建阶段也显式设置 DOCKER_ENV，
ENV DOCKER_ENV=true

# 生成生产构建
RUN npm run build

# ---- 第 2 阶段：生成运行时镜像 ----
FROM node:22-slim AS runner

# 创建非 root 用户
RUN groupadd --gid 1001 nodejs && useradd --uid 1001 --gid nodejs --shell /bin/bash --create-home nextjs

WORKDIR /app
ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3000
ENV DOCKER_ENV=true

# 从构建器中复制 standalone 输出（已包含必要的运行时依赖）
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
# 从构建器中复制 public 和 .next/static 目录
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# 切换到非特权用户
USER nextjs

EXPOSE 3000

# 启动 Next.js 应用
CMD ["node", "server.js"] 