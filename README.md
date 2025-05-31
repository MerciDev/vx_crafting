vx_crafting - Sistema de Crafteo Inmersivo para FiveM (QB-Core)
vx_crafting es un sistema de crafteo inmersivo y personalizable para servidores FiveM que utilizan QB-Core. Permite a los jugadores craftear objetos en puntos de crafteo definidos, con recetas que pueden requerir ingredientes, animaciones y notificaciones personalizadas.

Características
Puntos de Crafteo Configurables: Define ubicaciones específicas en el mapa donde los jugadores pueden craftear.

Recetas de Crafteo Flexibles: Crea recetas con múltiples ingredientes, tiempos de crafteo, animaciones y mensajes de rol.

Sistema de Aprendizaje de Recetas: Los jugadores deben aprender las recetas antes de poder craftearlas.

Interfaz de Usuario NUI: Una interfaz de usuario limpia e intuitiva para seleccionar y craftear recetas.

Soporte para ox_inventory y QB-Core Inventory: Compatible con ambos sistemas de inventario.

Notificaciones Personalizables: Utiliza ox_lib o QBCore:Notify para las notificaciones.

Animaciones y Congelación de Jugador: Define animaciones para el crafteo y congela al jugador durante el proceso.

Mensajes de Rol (ME/DO): Personaliza los mensajes de rol que aparecen durante el crafteo.

Instalación
Clona o descarga este repositorio.

Asegúrate de tener las dependencias: qb-core y ox_lib instaladas y funcionando en tu servidor.

Añade vx_crafting a tu server.cfg:

ensure ox_lib
ensure qb-core
ensure vx_crafting

Importa la base de datos: Ejecuta el archivo player_crafting_recipes.sql en tu base de datos MySQL.

Configura config.lua y shared/crafting_recipes.json según tus necesidades (ver secciones a continuación).

Asegúrate de que las imágenes de los ítems estén en la ruta shared/imgs/ dentro de la carpeta del recurso vx_crafting.

Configuración
config.lua
Este archivo contiene la configuración general del script y la definición de los puntos de crafteo.

Vx_crafting = Vx_crafting or {}

Vx_crafting.Config = {
    CommandPrefix = "vx_crafting", -- Prefijo para los comandos del script (ej: /vx_craftingcraft)
    InteractionCooldown = 1000,   -- Tiempo de espera entre interacciones (en milisegundos)
    InventorySystem = "ox_inventory", -- Sistema de inventario a usar: "ox_inventory" o "qbcore"
    ProgressBar = {
        TimePerItem = 2000,         -- Tiempo por defecto para la barra de progreso por cada ítem crafteado (en milisegundos)
        CancelKey = 73,             -- Tecla para cancelar la barra de progreso (por defecto: 73 para 'X')
    },
    NotificationSystem = "ox_lib",    -- Sistema de notificaciones: "ox_lib" o "qbcore"
    NotificationDuration = 5000,    -- Duración de las notificaciones (en milisegundos)
    DebugMode = false,              -- Habilita mensajes de depuración en la consola
    UseDrawText3D = false,          -- Usa DrawText3D en lugar de ox_lib textUI para el texto de interacción
}

Vx_crafting.CraftingPoints = {
    ["botanic"] = { -- ID único del punto de crafteo
        coords = vector3(7399.91, 7347.83, 15.57), -- Coordenadas del punto de interacción
        heading = 0.0, -- Orientación del objeto (si se usa)
        radius = 2.0,  -- Radio de detección para la interacción
        recipes = {},  -- Lista de IDs de recetas permitidas en este punto (ej: {"water_jug", "water_carafe_8l"})
                       -- Si se incluye "all", todas las recetas serán crafteables aquí.
        category = "botanic_1", -- Categoría de recetas permitidas en este punto.
                                -- Si se establece en "all", todas las recetas de cualquier categoría serán crafteables aquí.
        blip = { -- Configuración del blip en el mapa
            sprite = 478,
            color = 4,
            scale = 0.8,
            name = "Estación de Crafteo Botánico",
        },
        marker = { -- Configuración del marcador 3D
            type = 27, -- Tipo de marcador (ver FiveM Native Reference)
            coords = vector3(7399.91, 7347.83, 14.57), -- Coordenadas del marcador (puede ser ligeramente por debajo de coords)
            scale = vector3(2.0, 2.0, 1.0), -- Escala del marcador
            color = { 255, 150, 0, 100 },  -- Color del marcador (RGBA)
            drawDistance = 10.0,           -- Distancia a la que se dibuja el marcador
        },
        object = { -- Objeto 3D que se spawnea en el punto de crafteo
            model = 'bkr_prop_weed_table_01b', -- Modelo del objeto
            freeze = true,                     -- Congelar el objeto en su lugar
            placeOnGround = true,              -- Intentar colocar el objeto en el suelo
            zOffset = -1.9,                    -- Ajuste vertical del objeto si placeOnGround es true
        },
    },
    -- Puedes añadir más puntos de crafteo aquí
}

shared/crafting_recipes.json
Este archivo define todas las recetas de crafteo disponibles en el servidor. Es un objeto JSON donde cada clave es el id único de la receta.

{
  "water_jug": {
    "id": "water_jug",
    "name": "Water Jug",
    "description": "A large container for water, useful for hydration.",
    "category": "consumables",
    "image": "water_jug.png",
    "ingredients": [
      {
        "name": "water",
        "label": "Water",
        "amount": 1,
        "consumable": true,           // (Opcional, por defecto true) Si el ingrediente se consume.
        "consumable_on_init": true    // (Opcional, por defecto false) Si el ingrediente se consume al inicio del crafteo (true) o al final (false).
                                      // Útil para crafteos con múltiples ítems donde quieres que los ingredientes se consuman por cada ítem.
      }
    ],
    "output": {
      "name": "water",
      "label": "Water",
      "amount": 10
    },
    "craftingTime": 20000,          // Tiempo de crafteo para UNA UNIDAD de este ítem (en milisegundos).
                                    // Si se craftean 5 unidades, el tiempo total será 5 * craftingTime.
    "animation": {
      "dict": "missmechanic",       // Diccionario de animación
      "anim": "work2_base"          // Nombre de la animación
    },
    "freezePlayer": true,           // Congelar al jugador durante la animación de crafteo
    "me_start": "comienza a llenar %quantity% %name%/s de agua.",    // Mensaje /me al inicio del crafteo
    "repeat_start": false,          // Si el mensaje de inicio se repite por cada ítem crafteado
    "me_end": "sella el  %name% y lo deja a un lado.",               // Mensaje /me al final del crafteo de un ítem
    "do_end": "se verian %current_item% %name%/s a un lado llenos de agua.", // Mensaje /do al final del crafteo de un ítem
    "repeat_end": true              // Si el mensaje de fin se repite por cada ítem crafteado
  }
}

Propiedades de la Receta
id (string): ID único de la receta. Debe coincidir con la clave del objeto.

name (string): Nombre visible de la receta en la UI.

description (string): Descripción de la receta.

category (string): Categoría a la que pertenece la receta. Se usa para filtrar recetas en los puntos de crafteo.

image (string): Nombre del archivo de imagen del ítem de salida (ej: "water_jug.png"). Debe estar en shared/imgs/.

ingredients (array de objetos): Lista de ingredientes necesarios para craftear una unidad del output.

name (string): Nombre del ítem (identificador del inventario).

label (string): Etiqueta visible del ingrediente (si es diferente al name).

amount (number): Cantidad requerida de este ingrediente.

consumable (boolean, opcional, por defecto true): Si el ingrediente se consume al craftear.

consumable_on_init (boolean, opcional, por defecto false): Si el ingrediente se consume al inicio del crafteo (antes de la barra de progreso) o al final (después de la barra de progreso). Esto es por cada unidad crafteada.

output (objeto): El ítem que se produce al craftear esta receta.

name (string): Nombre del ítem de salida (identificador del inventario).

label (string): Etiqueta visible del ítem de salida.

amount (number): Cantidad de ítems de salida producidos por cada crafteo.

craftingTime (number): Tiempo en milisegundos que tarda en craftear una unidad de este ítem. Si se craftean múltiples unidades, este tiempo se multiplica por la cantidad. Si no se especifica, usa Vx_crafting.Config.ProgressBar.TimePerItem.

animation (objeto, opcional): Animación que el jugador realizará durante el crafteo.

dict (string): Diccionario de animación.

anim (string): Nombre de la animación.

freezePlayer (boolean, opcional, por defecto false): Si el jugador debe ser congelado en su posición durante el crafteo.

me_start (string, opcional): Mensaje de rol /me que se ejecuta al inicio de cada ciclo de crafteo de un ítem.

do_start (string, opcional): Mensaje de rol /do que se ejecuta al inicio de cada ciclo de crafteo de un ítem.

repeat_start (boolean, opcional, por defecto false): Si los mensajes me_start y do_start se repiten para cada ítem crafteado en una cola, o solo una vez al inicio del proceso completo.

me_end (string, opcional): Mensaje de rol /me que se ejecuta al final de cada ciclo de crafteo de un ítem.

do_end (string, opcional): Mensaje de rol /do que se ejecuta al final de cada ciclo de crafteo de un ítem.

repeat_end (boolean, opcional, por defecto false): Si los mensajes me_end y do_end se repiten para cada ítem crafteado en una cola, o solo una vez al final del proceso completo.

Reemplazos de Placeholders en Mensajes ME/DO
Puedes usar los siguientes placeholders en los mensajes me_start, do_start, me_end, do_end:

%quantity%: La cantidad total de ítems que el jugador intenta craftear en esa sesión.

%name%: El nombre del ítem que se está crafteando (el name de la receta).

%category%: La categoría de la receta.

%current_item%: El número del ítem actual que se está crafteando en la secuencia (ej: 1 de 5, 2 de 5, etc.).

%total_items%: La cantidad total de ítems que se están crafteando en la sesión.

%player_name%: El nombre del jugador que está crafteando.

fxmanifest.lua
Asegúrate de que tu fxmanifest.lua incluya todas las dependencias y archivos necesarios:

fx_version 'cerulean'
game 'gta5'

author 'MiritoKaba (Vortex)'
description 'Immersive crafting and order system for QB-Core.'
version '1.0.0'

dependencies {
    'qb-core',
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
    'config.lua',
    'shared/crafting_recipes.json', -- Asegúrate de que esta línea esté presente
}

client_scripts {
    'client/cl_crafting.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_crafting.lua',
}

ui_page 'craftingui/index.html'

files {
    'craftingui/index.html',
    'craftingui/style.css',
    'craftingui/script.js',
    'shared/crafting_recipes.json',
    'shared/imgs/*.png', -- Asegúrate de incluir esta línea para las imágenes
}

lua54 'yes'

Uso
Comandos del Jugador
/vx_craftingcraft [ID_PUNTO_CRAFTEO]: Abre la interfaz de crafteo en un punto específico. Si no se proporciona un ID, intentará abrir la estación de crafteo por defecto (si está configurada).

Comandos de Administrador (o para aprender recetas)
/learncraftingrecipe [ID_RECETA]: Permite a un administrador enseñar una receta a un jugador.

Aprendizaje de Recetas (Función Exportada)
Puedes usar la función exportada LearnRecipe desde otros scripts para que los jugadores aprendan nuevas recetas.

Ejemplo (en otro script de servidor):

-- Para enseñar una receta a un jugador
exports['vx_crafting']:LearnRecipe(source, 'water_jug')

Estructura de Archivos
vx_crafting/
├── client/
│   └── cl_crafting.lua         -- Lógica del lado del cliente (interacciones, UI, animaciones)
├── craftingui/
│   ├── index.html              -- Interfaz de usuario NUI
│   ├── script.js               -- Lógica JavaScript para la UI
│   └── style.css               -- Estilos CSS para la UI
├── server/
│   └── sv_crafting.lua         -- Lógica del lado del servidor (manejo de crafteo, inventario, DB)
├── shared/
│   ├── crafting_recipes.json   -- Definición de todas las recetas de crafteo
│   └── imgs/                   -- Carpeta para las imágenes de los ítems
├── config.lua                  -- Configuración general y puntos de crafteo
├── fxmanifest.lua              -- Manifiesto del recurso FiveM
└── player_crafting_recipes.sql -- Esquema de la tabla de la base de datos para recetas conocidas

¡Esperamos que disfrutes usando vx_crafting en tu servidor FiveM! Si tienes alguna pregunta o encuentras algún problema, no dudes en abrir un issue en GitHub.