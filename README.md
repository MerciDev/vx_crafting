vx_crafting – Sistema de Crafteo Inmersivo para FiveM (QB-Core)
vx_crafting es un sistema de crafteo inmersivo y altamente personalizable diseñado para servidores FiveM que utilizan QB-Core. Permite a los jugadores fabricar objetos en ubicaciones específicas del mapa, con recetas detalladas, animaciones únicas y mensajes de rol dinámicos.

🧭 Tabla de Contenidos
Características

Instalación

Configuración

config.lua

shared/crafting_recipes.json

Propiedades de la Receta

Placeholders en Mensajes ME/DO

fxmanifest.lua

Uso

Comandos del Jugador

Comandos de Administrador

Aprendizaje de Recetas

Estructura de Archivos

Contribuciones

Licencia

🛠️ Características
Puntos de Crafteo Configurables: Define ubicaciones específicas con blips, marcadores y objetos 3D personalizables.

Recetas Flexibles: Múltiples ingredientes, tiempos, animaciones y mensajes de rol por receta.

Sistema de Aprendizaje: Las recetas deben ser aprendidas antes de craftearse.

UI NUI Moderna: Interfaz intuitiva y elegante.

Compatibilidad de Inventario: Soporte para ox_inventory y qbcore.

Notificaciones Personalizables: Usa ox_lib o QBCore:Notify.

Animaciones y Congelación: Totalmente personalizable por receta.

Mensajes ME/DO: Rol dinámico con uso de placeholders.

📦 Instalación
Clona o descarga este repositorio en tu carpeta resources/.

Asegúrate de tener qb-core y ox_lib instalados.

Añade esto en tu server.cfg:

c
Copiar
Editar
ensure ox_lib
ensure qb-core
ensure vx_crafting
Importa la base de datos: ejecuta player_crafting_recipes.sql en tu MySQL.

Configura config.lua y shared/crafting_recipes.json a tus necesidades.

Asegúrate de que las imágenes de ítems estén en shared/imgs/.

⚙️ Configuración
config.lua
lua
Copiar
Editar
Vx_crafting = Vx_crafting or {}

Vx_crafting.Config = {
    CommandPrefix = "vx_crafting",
    InteractionCooldown = 1000,
    InventorySystem = "ox_inventory",
    ProgressBar = {
        TimePerItem = 2000,
        CancelKey = 73,
    },
    NotificationSystem = "ox_lib",
    NotificationDuration = 5000,
    DebugMode = false,
    UseDrawText3D = false,
}
Ejemplo de Punto de Crafteo
lua
Copiar
Editar
Vx_crafting.CraftingPoints = {
  ["botanic"] = {
    coords = vector3(7399.91, 7347.83, 15.57),
    heading = 0.0,
    radius = 2.0,
    recipes = {"water_jug"},
    category = "botanic_1",
    blip = {
      sprite = 478,
      color = 4,
      scale = 0.8,
      name = "Estación de Crafteo Botánico",
    },
    marker = {
      type = 27,
      coords = vector3(7399.91, 7347.83, 14.57),
      scale = vector3(2.0, 2.0, 1.0),
      color = {255, 150, 0, 100},
      drawDistance = 10.0,
    },
    object = {
      model = 'bkr_prop_weed_table_01b',
      freeze = true,
      placeOnGround = true,
      zOffset = -1.9,
    },
  },
}
shared/crafting_recipes.json
json
Copiar
Editar
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
        "consumable": true,
        "consumable_on_init": true
      }
    ],
    "output": {
      "name": "water",
      "label": "Water",
      "amount": 10
    },
    "craftingTime": 20000,
    "animation": {
      "dict": "missmechanic",
      "anim": "work2_base"
    },
    "freezePlayer": true,
    "me_start": "comienza a llenar %quantity% %name%/s de agua.",
    "repeat_start": false,
    "me_end": "sella el %name% y lo deja a un lado.",
    "do_end": "se verían %current_item% %name%/s a un lado llenos de agua.",
    "repeat_end": true
  }
}
🧪 Propiedades de la Receta
Propiedad	Tipo	Descripción
id	string	Identificador único de la receta.
name	string	Nombre visible de la receta.
description	string	Descripción breve.
category	string	Categoría usada para filtrar recetas por punto.
image	string	Imagen del ítem de salida (ubicada en shared/imgs/).
ingredients	array	Lista de ingredientes (ver formato más arriba).
output	object	Ítem resultante con name, label, y amount.
craftingTime	number	Tiempo de crafteo por unidad (ms).
animation	object	Diccionario y nombre de la animación.
freezePlayer	bool	Si se congela al jugador durante el proceso.
me_start, me_end	string	Mensajes de rol /me.
do_end	string	Mensaje de rol /do.
repeat_*	bool	Si los mensajes se repiten por cada unidad crafteada.

🧩 Placeholders en Mensajes ME/DO
Puedes usar los siguientes placeholders en los mensajes de rol:

%name%: Nombre del ítem

%label%: Etiqueta del ítem

%quantity%: Cantidad total a craftear

%current_item%: Número actual del ítem que se está crafteando

📄 fxmanifest.lua
Asegúrate de que el archivo fxmanifest.lua contenga las dependencias y archivos necesarios:

lua
Copiar
Editar
fx_version 'cerulean'
game 'gta5'

description 'vx_crafting - Sistema de Crafteo Inmersivo para QB-Core'
author 'TuNombre'

shared_scripts {
  '@ox_lib/init.lua',
  'shared/*.lua',
  'shared/*.json'
}

client_scripts {
  'client/*.lua'
}

server_scripts {
  'server/*.lua'
}

lua54 'yes'
🎮 Uso
Comandos del Jugador
/vx_craftingcraft – Abre la interfaz de crafteo (configurable en config.lua).

Comandos de Administrador
/vx_learnrecipe [id_receta] – Enseña una receta al jugador.

Aprendizaje de Recetas (Función Exportada)
lua
Copiar
Editar
exports['vx_crafting']:LearnRecipe(source, 'water_jug')
📁 Estructura de Archivos
pgsql
Copiar
Editar
vx_crafting/
│
├── client/
│   └── main.lua
├── server/
│   └── main.lua
├── shared/
│   ├── config.lua
│   ├── crafting_recipes.json
│   └── imgs/
├── ui/
│   └── index.html
├── fxmanifest.lua
└── player_crafting_recipes.sql
🤝 Contribuciones
Las contribuciones son bienvenidas. Por favor, abre un Pull Request o reporta un problema mediante Issues si encuentras errores o tienes sugerencias.

📜 Licencia
Este recurso está licenciado bajo la MIT License.