# ⚒️ vx_crafting – Sistema de Crafteo Inmersivo para FiveM (QB-Core)

**vx_crafting** es un sistema de crafteo inmersivo y altamente personalizable diseñado para servidores FiveM que utilizan **QB-Core**. Permite a los jugadores fabricar objetos en ubicaciones específicas del mapa, con recetas detalladas, animaciones únicas y mensajes de rol dinámicos.

---

## 🧭 Tabla de Contenidos

- [⚒️ vx\_crafting – Sistema de Crafteo Inmersivo para FiveM (QB-Core)](#️-vx_crafting--sistema-de-crafteo-inmersivo-para-fivem-qb-core)
  - [🧭 Tabla de Contenidos](#-tabla-de-contenidos)
  - [🛠️ Características](#️-características)
  - [📦 Instalación](#-instalación)
  - [⚙️ Configuración](#️-configuración)
    - [config.lua](#configlua)
    - [🧪 Ejemplo de Punto de Crafteo](#-ejemplo-de-punto-de-crafteo)
    - [📄 shared/crafting\_recipes.json](#-sharedcrafting_recipesjson)

---

## 🛠️ Características

- **Puntos de Crafteo Configurables:** Define ubicaciones específicas con blips, marcadores y objetos 3D personalizables.  
- **Recetas Flexibles:** Múltiples ingredientes, tiempos, animaciones y mensajes de rol por receta.  
- **Sistema de Aprendizaje:** Las recetas deben ser aprendidas antes de craftearse.  
- **UI NUI Moderna:** Interfaz intuitiva y elegante.  
- **Compatibilidad de Inventario:** Soporte para `ox_inventory` y `qbcore`.  
- **Notificaciones Personalizables:** Usa `ox_lib` o `QBCore:Notify`.  
- **Animaciones y Congelación:** Totalmente personalizable por receta.  
- **Mensajes ME/DO:** Rol dinámico con uso de *placeholders*.  

---

## 📦 Instalación

1. Clona o descarga este repositorio en tu carpeta `resources/`.  
2. Asegúrate de tener `qb-core` y `ox_lib` instalados.  
3. Añade esto en tu `server.cfg`:
4. Importa la base de datos: ejecuta `player_crafting_recipes.sql` en tu MySQL.  
5. Configura `config.lua` y `shared/crafting_recipes.json` a tus necesidades.  
6. Asegúrate de que las imágenes de ítems estén en `shared/imgs/`.  

---

## ⚙️ Configuración

### config.lua

```lua
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
```

### 🧪 Ejemplo de Punto de Crafteo

```lua
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
```

### 📄 shared/crafting_recipes.json

```json
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
```

🧪 **Propiedades de la Receta**

| Propiedad     | Tipo    | Descripción                                         |
|---------------|---------|-----------------------------------------------------|
| `id`          | string  | Identificador único de la receta.                   |
| `name`        | string  | Nombre visible de la receta.                         |
| `description` | string  | Descripción breve.                                   |
| `category`    | string  | Categoría usada para filtrar recetas por punto.     |
| `image`       | string  | Imagen del ítem de salida (ubicada en `shared/imgs/`). |
| `ingredients` | array   | Lista de ingredientes (ver formato más arriba).     |
| `output`      | object  | Ítem resultante con `name`, `label`, y `amount`.    |
| `craftingTime`| number  | Tiempo de crafteo por unidad (ms).                   |
| `animation`   | object  | Diccionario y nombre de la animación.                |
| `freezePlayer`| bool    | Si se congela al jugador durante el proceso.        |
| `me_start`    | string  | Mensaje de rol `/me` al comenzar.                    |
| `me_end`      | string  | Mensaje de rol `/me` al terminar.                    |
| `do_end`      | string  | Mensaje de rol `/do` al terminar.                    |
| `repeat_start`| bool    | Si el mensaje de inicio se repite por cada unidad.  |
| `repeat_end`  | bool    | Si el mensaje de fin se repite por cada unidad.     |

🧩 Placeholders en Mensajes ME/DO  
Puedes usar los siguientes placeholders en los mensajes de rol:

- `%name%`: Nombre del ítem  
- `%label%`: Etiqueta del ítem  
- `%quantity%`: Cantidad total a craftear  
- `%current_item%`: Número actual del ítem que se está crafteando
- `%player_name%`: Nombre del jugador que está crafteando

🎮 **Uso**

**Comandos del Jugador**  
`/vx_crafting:ui [id_interfaz]` – Abre la interfaz de crafteo (configurable en `config.lua`).

**Comandos de Administrador**  
`/vx_crafting:learn [id_jugador] [id_receta]` – Enseña una receta al jugador.

**Aprendizaje de Recetas (Función Exportada)**  
```lua
exports['vx_crafting']:LearnRecipe(source, 1, 'water_jug')
```
