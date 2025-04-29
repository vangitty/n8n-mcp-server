# Stage 1: Build the application
FROM node:22-alpine AS builder
WORKDIR /app

# Kopiere ALLE Dateien ZUERST, inklusive package*.json, tsconfig.json, src/ etc.
COPY . .

# Führe npm ci JETZT aus.
# Das inkludierte 'prepare'-Skript führt 'npm run build' aus.
# Da jetzt alle Dateien vorhanden sind, sollte 'tsc' erfolgreich sein.
RUN npm ci

# Optional, aber empfohlen: Entferne devDependencies nach dem Build.
RUN npm prune --omit=dev

# Stage 2: Create the final production image
FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production

# Kopiere notwendige Artefakte aus der Builder-Stage
# package.json wird für Metadaten wie "type": "module" benötigt
COPY --from=builder /app/package.json ./package.json
# Kopiere die Produktions-node_modules (wurden oben gepruned)
COPY --from=builder /app/node_modules ./node_modules
# Kopiere die gebaute Anwendung
COPY --from=builder /app/build ./build

# Port, auf dem die Anwendung lauscht (Annahme: 3000)
EXPOSE 3000

# Wechsle zu einem non-root User
USER node

# Standard-Startbefehl
CMD ["node", "./build/index.js"]
