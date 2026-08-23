# ---- Dependencies ----
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install

# ---- Build (Next.js standalone) ----
FROM node:20-alpine AS build
WORKDIR /app
ARG NEXT_PUBLIC_APK_URL=https://media.pitgo.uz/pitgo-2.1.0.apk
ENV NEXT_PUBLIC_APK_URL=$NEXT_PUBLIC_APK_URL
ARG NEXT_PUBLIC_APK_PRO_URL=https://media.pitgo.uz/pitgo-pro-2.1.0.apk
ENV NEXT_PUBLIC_APK_PRO_URL=$NEXT_PUBLIC_APK_PRO_URL
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# ---- Runtime ----
FROM node:20-alpine AS run
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=build /app/public ./public
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static
EXPOSE 3000
CMD ["node", "server.js"]
