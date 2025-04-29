# Stage 1: Build the application
FROM node:22-alpine AS builder
WORKDIR /app

# Copy package files FIRST for cache efficiency
COPY package*.json ./

# Install ALL dependencies (including devDependencies) needed for the build
RUN npm ci

# Copy the rest of the application source code
COPY . .

# Run the build script explicitly now that all source code is present
# (Auch wenn 'prepare' es evtl. schon versucht hat, dieser Lauf hat alle Dateien)
RUN npm run build

# Optional: Hier könnte man mit `RUN npm prune --omit=dev` aufräumen,
# aber für die nächste Stufe ist es einfacher, nur Produktions-Deps neu zu installieren.

# Stage 2: Create the final production image
FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production

# Kopiere nur package files, um nur Produktions-Abhängigkeiten zu installieren
COPY --from=builder /app/package.json ./package.json
# Kopiere evtl. vorhandene package-lock.json für konsistente Installation
COPY --from=builder /app/package-lock.json* ./package-lock.json 2>/dev/null || true

# Installiere NUR Produktions-Abhängigkeiten
RUN npm ci --omit=dev

# Kopiere die gebaute Anwendung aus der Builder-Stage
COPY --from=builder /app/build ./build

# Port, auf dem die Anwendung lauscht (Annahme: 3000)
EXPOSE 3000

# Wechsle zu einem non-root User
USER node

# Standard-Startbefehl
CMD ["node", "./build/index.js"]
