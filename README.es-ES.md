# Introducción

Scretch.nvim es un plugin para crear y gestionar archivos temporales (scratch files) fácilmente 🙂.

## Características
### Nuevo scretch

https://github.com/user-attachments/assets/0fcb1c48-28fe-4ba9-bfc7-231bf8a19459

### Nuevo scretch con nombre

https://github.com/user-attachments/assets/35e5e860-b578-4f35-beca-c14e9a0468da

### ¡Busca, usa grep y explora tus scretches!

https://github.com/user-attachments/assets/467bdaeb-8c6b-4134-8f18-c651a3f60d74

### Plantillas (Templates)

Puedes guardar cualquier buffer como una plantilla de Scretch. Se guardará en el directorio predeterminado si no se especifica uno explícitamente en la configuración.
También puedes buscar y editar plantillas con Telescope o Fzf-Lua, y crear un nuevo Scretch a partir de una plantilla.
Consulta los [mapeos sugeridos](#suggested-mappings).

### Scretches con ámbito (Scoped)

Con la función `project_dir`, puedes indicarle a scretch que cree archivos en el directorio de tu proyecto en una carpeta dedicada.
Puedes usar la configuración para establecer este comportamiento como predeterminado, o anularlo temporalmente con los comandos dedicados (ver [mapeos sugeridos](#suggested-mappings)).
Puedes especificar el uso para archivos scretch, plantillas, o ambos.

Una vez que hayas cambiado al modo de proyecto, los demás comandos se adaptan: si utilizas el buscador difuso (fuzzy finder) con las funciones dedicadas, buscará en el directorio de scretch de tu proyecto.

# Instalación

Este plugin requiere Telescope o fzf-lua y ripgrep para funcionar.

Si no tienes ripgrep instalado, te recomiendo revisar el procedimiento de instalación [aquí](https://github.com/BurntSushi/ripgrep#installation).
Si no deseas instalarlo, debería hacer un fallback a `find`.

Puedes pegar el siguiente código usando Packer, o adaptarlo a tu gestor de paquetes favorito:

```lua
-- Lazy
{
  '0xJohnnyboy/scretch.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  -- o
  -- dependencies = { 'ibhagwan/fzf-lua' },
  config = function()
    require('scretch').setup({
      -- tu configuración va aquí
      -- o déjalo vacío para usar los ajustes predeterminados
      -- consulta la sección de configuración más abajo
    })
  end,
},
```

```lua  
-- Packer
use {
  '0xJohnnyboy/scretch.nvim',
  requires = 'nvim-telescope/telescope.nvim',
  -- o
  -- requires = 'ibhagwan/fzf-lua' ,
  config = function()
    require('scretch').setup {
      -- tu configuración va aquí
      -- o déjalo vacío para usar los ajustes predeterminados
      -- consulta la sección de configuración más abajo
    }
  end
}
```

# Configuración

Aquí están los ajustes predeterminados utilizados en Scretch:
```lua
local config = {
    scretch_dir = vim.fn.stdpath('data') .. '/scretch/', -- se creará si no existe
    template_dir = vim.fn.stdpath('data') .. '/scretch/templates', -- se creará si no existe
    use_project_dir = {
        auto_create_project_dir = false,
        scretch = false,  -- false | true | auto
        scretch_project_dir = ".scretch/",
        template = false, -- false | true | auto
        template_project_dir = ".scretch/templates/",
    },
    default_name = "scretch_",
    default_type = "txt", -- los Scretches anónimos predeterminados se nombran "scretch_*.txt"
    split_cmd = "vsplit", -- comando de split de vim utilizado al crear un nuevo Scretch
    backend = "telescope.builtin", -- también acepta "fzf-lua"
    template_variables = {
        enabled = true,
        date = {
            enabled = true,
            value = "now",
            default_format = "YYYY-MM-dd",
        },
        title = {
            enabled = true,
            source = "filename",
        },
        author = {
            enabled = true,
            source = "shell", -- shell | git | literal
            value = "",
        },
        custom = {
            -- project = function(ctx) return vim.fn.fnamemodify(ctx.cwd, ":t") end,
        },
    },
}
```
Puedes copiar estos ajustes, actualizarlos según tus preferencias y ponerlos en la función setup para cargarlos.

Si estás considerando usar la función `project_dir`, deberías añadir el directorio de proyecto a tu `.gitignore` (siendo `.scretch` el valor predeterminado).

## Variables de plantilla

Las variables de plantilla se renderizan al crear una nota con `new_from_template()`.
No se renderizan al guardar plantillas.

Sintaxis:

```txt
{{ variable }}
{{ variable | uppercase }}
{{ date | format:YYYY/MM/dd }}
```

Variables integradas:
- `title`: nombre del archivo objetivo sin extensión
- `date`: fecha/hora actual
- `author`: resuelto desde la configuración (`shell`, `git` o `literal`)

Filtros integrados:
- `uppercase`
- `lowercase`
- `trim`
- `format:<pattern>` (principalmente para `date`)

En caso de variable/filtro desconocido o error de renderizado, Scretch lo reemplaza con una cadena vacía y envía una advertencia vía `vim.notify` (visible en `:messages`).

## Mapeos sugeridos

```lua
local s = require("scretch")
vim.keymap.set('n', '<leader>sn', s.new)
vim.keymap.set('n', '<leader>snn', s.new_named)
vim.keymap.set('n', '<leader>sft', s.new_from_template)
vim.keymap.set('n', '<leader>sl', s.last)
vim.keymap.set('n', '<leader>ss', s.search)
vim.keymap.set('n', '<leader>st', s.edit_template)
vim.keymap.set('n', '<leader>sg', s.grep)
vim.keymap.set('n', '<leader>sv', s.explore)
vim.keymap.set('n', '<leader>sat', s.save_as_template)


vim.keymap.set('n', '<leader>smsp' s.scretch_use_project_mode)
vim.keymap.set('n', '<leader>smsa' s.scretch_use_auto_mode)
vim.keymap.set('n', '<leader>smsg' s.scretch_use_global_mode)
vim.keymap.set('n', '<leader>smtp' s.template_use_project_mode)
vim.keymap.set('n', '<leader>smta' s.template_use_auto_mode)
vim.keymap.set('n', '<leader>smtg' s.template_use_global_mode)
```

## Uso
Puedes usar los mapeos anteriores, o llamar directamente a cualquier función con

```vim
:Scretch <function>
```

Para documentación detallada que incluye opciones de configuración, todas las funciones disponibles y ejemplos:

```vim
:h scretch
```

También puedes saltar directamente a secciones específicas:
- `:h scretch-configuration` - Opciones de configuración  
- `:h scretch-functions` - Todas las funciones disponibles
- `:h scretch-modes` - Entendiendo los modos global/proyecto/auto

# Relacionados
Scretch.nvim, con las nuevas variables de plantilla, se integra bien con [`vo`](https://github.com/0xJohnnyboy/voyage) y [voyage.nvim](https://github.com/0xJohnnyboy/voyage.nvim) para un flujo de trabajo de toma de notas ligero tipo zettelkasten. Estos permiten navegar por las relaciones de las notas mediante wikilinks, etiquetas o categorías.

# Problemas (Issues)

Siéntete libre de abrir issues si tienes alguna sugerencia o encuentras un error. ¡Sé amable!

# Licencia

AGPL-3.0, ver [archivo de licencia](./LICENSE.md)

# Contribución

Siéntete libre de enviar PRs, estas deben respetar las [pautas de contribución](./CONTRIBUTING.md). ¡Sé amable!
