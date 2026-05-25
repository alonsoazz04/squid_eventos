# Trabajo teórico-práctico: eventos con Squid y Telegram

Este proyecto amplía la práctica anterior de balanceo de carga con **Squid** para generar una notificación cada vez que un cliente realiza una petición al balanceador. El enunciado indica que, para los componentes de balanceo de carga, debe generarse un evento por cada petición del cliente, informando de la operación, la dirección del cliente y el recurso solicitado, y especifica que en **Squid** una solución válida es analizar sus logs en tiempo real para emitir notificaciones.[1]

La solución implementada consiste en monitorizar el fichero `access.log` de Squid en tiempo real y enviar una alerta a **Telegram** mediante un bot cada vez que se detecta una nueva petición HTTP. De esta forma, se cumple el requisito de capturar eventos sobre el balanceador y demostrar su señalización mediante una notificación externa.[1]

## Objetivo

El objetivo de esta práctica es detectar eventos generados por las peticiones entrantes al balanceador Squid y notificar dichos eventos automáticamente. Según el documento de la práctica, el evento debe informar de qué operación realiza el cliente, su dirección IP y sobre qué elemento actúa, por ejemplo `cliente 192.168.1.2 GET /status.html`.[1]

## Maqueta de demostración

La maqueta utilizada parte del trabajo anterior y está formada por los siguientes elementos:

- **Frontend**: un contenedor Docker con Squid actuando como reverse proxy/balanceador.[1]
- **Backends**: dos o tres contenedores HTTP ligeros (`be1`, `be2`, `be3`) usados para responder a las peticiones.
- **Watcher de eventos**: un script que analiza en tiempo real `access.log` de Squid.[1]
- **Canal de notificación**: un bot de Telegram que recibe el aviso generado por cada nueva petición.[1]

## Funcionamiento

El flujo de la solución es el siguiente:

1. Un cliente realiza una petición HTTP al frontend Squid.
2. Squid registra la petición en `access.log`.[1]
3. El script `watch_squid_events.sh` detecta una nueva línea en el log y extrae la información relevante.
4. El script construye un mensaje con la IP del cliente y el recurso solicitado.
5. El mensaje se envía a Telegram usando la API HTTP del bot.

## Estructura del repositorio

```text
.
├── docker-compose.yml
├── squid/
│   └── squid.conf
├── logs/
│   ├── access.log
│   └── cache.log
├── scripts/
│   ├── watch_squid_events.sh
│   └── send_telegram.sh
└── README.md
```

## Requisitos

- Ubuntu con Docker y Docker Compose plugin instalados.
- Bot de Telegram creado con **BotFather**.
- `BOT_TOKEN` y `CHAT_ID` obtenidos previamente.
- Demo base de Squid operativa.

## Configuración

### 1. Crear el bot de Telegram

Se debe crear un bot con **@BotFather** y obtener su token HTTP API. Además, es necesario iniciar conversación con el bot y obtener el `CHAT_ID` mediante la API `getUpdates` o bots auxiliares de identificación.

> **Importante**: el token del bot no debe subirse al repositorio.

### 2. Configurar Squid

El fichero `squid/squid.conf` debe incluir el registro de accesos, ya que el enunciado propone analizar los logs de Squid en tiempo real para generar notificaciones.[1]

Ejemplo de líneas relevantes:

```conf
http_port 8080 accel defaultsite=demo.local no-vhost
http_access allow all

cache_peer be1 parent 80 0 no-query originserver round-robin name=be1
cache_peer be2 parent 80 0 no-query originserver round-robin name=be2
cache_peer_access be1 allow all
cache_peer_access be2 allow all

access_log stdio:/var/log/squid/access.log
cache_log /var/log/squid/cache.log
```

### 3. Montar los logs en el host

En `docker-compose.yml`, el contenedor de Squid debe montar el directorio de logs para que el watcher pueda leerlos desde el sistema anfitrión:

```yaml
services:
  squid-fe:
    image: ubuntu/squid:latest
    container_name: squid-fe
    ports:
      - "8080:8080"
    volumes:
      - ./squid/squid.conf:/etc/squid/squid.conf
      - ./logs:/var/log/squid
```

### 4. Ajustar permisos

Para la maqueta de laboratorio, el directorio `logs/` debe ser escribible por el usuario interno de Squid (`proxy`) y legible desde el host. Si aparecen errores de permisos al arrancar Squid o al leer el log, deben corregirse los permisos del directorio y de los ficheros generados.

## Scripts

### `send_telegram.sh`

Script encargado de enviar mensajes a Telegram mediante la API del bot.

### `watch_squid_events.sh`

Script encargado de monitorizar `logs/access.log` con `tail -F`, extraer la IP del cliente y la petición registrada, y llamar al script de envío a Telegram.

## Ejecución

### 1. Levantar la maqueta

```bash
docker compose up -d
```

### 2. Comprobar que Squid está operativo

```bash
curl http://localhost:8080/
```

### 3. Lanzar el watcher

```bash
./scripts/watch_squid_events.sh "BOT_TOKEN" "CHAT_ID" "logs/access.log"
```

### 4. Generar el evento

Desde otra terminal:

```bash
curl http://localhost:8081/
```

### 5. Verificar la notificación

Al realizar la petición, debe recibirse un mensaje en Telegram con información del evento detectado.

## Demostración en vídeo

El enunciado establece que el vídeo debe incluir tres partes: los pasos de configuración de la captura de eventos, una explicación breve de la maqueta y la demostración del evento generando la notificación.[1]

Una propuesta de guion es:

1. Mostrar la arquitectura: Squid + backends + watcher + Telegram.
2. Enseñar `squid.conf` y los scripts usados.
3. Lanzar el watcher.
4. Ejecutar `curl` contra Squid.
5. Mostrar el mensaje recibido en Telegram.

## Incidencias encontradas

Durante la implementación aparecieron varios problemas prácticos:

- Conflictos con el puerto publicado del frontend en el host.
- Problemas de permisos sobre `logs/access.log` y `logs/cache.log`.
- Dificultades para parar contenedores en Docker por errores de permisos del sistema.
- Necesidad de adaptar el watcher al formato real del log de Squid.

Estas incidencias forman parte de la puesta en marcha real de la maqueta y ayudan a justificar las decisiones de configuración adoptadas durante la práctica.

## Resultado

El resultado final es una ampliación funcional del balanceador Squid capaz de detectar en tiempo real cada petición de cliente y señalizarla mediante una notificación de Telegram. Esto cumple el objetivo del trabajo, que consiste en ampliar la demo anterior con un mecanismo de captura y notificación de eventos asociado a la operación habitual del servicio.[1]
