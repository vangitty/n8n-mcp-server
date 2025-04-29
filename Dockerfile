# Stage 1: Build the application
# Verwende eine Node.js Alpine Version (kleiner), Version >=18, 22 wie von Nixpacks verwendet
FROM node:22-alpine AS builder
WORKDIR /app

# Kopiere package.json und package-lock.json (falls vorhanden)
# Installiere ALLE Abhängigkeiten (inkl. devDependencies für den Build)
# `npm ci` führt automatisch das "prepare"-Skript aus (`npm run build`)
COPY package*.json ./
RUN npm ci

# Kopiere den Rest des Quellcodes (könnte für den Build benötigt werden)
COPY . .

# Optional: Den Build explizit nochmal laufen lassen, falls "prepare" nicht reicht.
# Normalerweise durch `npm ci` oben schon erledigt.
# RUN npm run build

# --- Optional: Dev-Abhängigkeiten entfernen ---
# Wenn du das finale Image noch kleiner machen willst, kannst du hier
# `RUN npm prune --production` ausführen, nachdem der Build abgeschlossen ist.
# Im Moment lassen wir es weg, um Komplexität zu reduzieren.

# Stage 2: Create the final production image
FROM node:22-alpine
WORKDIR /app

# Wichtig für Sicherheit und korrekte Modulauflösung
ENV NODE_ENV=production

# Kopiere notwendige Artefakte aus der Builder-Stage
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/build ./build

# Port, auf dem die Anwendung lauscht.
# Aus deiner vorherigen Coolify-Konfig nehme ich an, es ist 3000.
# Passe dies an, falls es ein anderer Port ist!
EXPOSE 3000

# Wechsle zu einem non-root User für bessere Sicherheit
USER node

# Standard-Startbefehl für den Container
CMD ["node", "./build/index.js"]
