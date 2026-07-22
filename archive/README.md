# 📂 Archivo: Versión Histórica 

## Versiones con webR / Shiny

Este directorio contiene la implementación previa de la herramienta de distribución interdoméstica desarrollada con **Quarto + webR + Shiny**. 

Actualmente, el proyecto principal migró a **Observable JS (OJS)** para mejorar los tiempos de carga inicial y la reactividad nativa en el navegador, eliminando la necesidad de montar un entorno webR completo. Sin embargo, se conserva este archivo por su valor arquitectónico y lógicas de R útiles.

 ---  

## 🛠️ Especificaciones Técnicas de esta Versión

* **Motor de Ejecución:** `webR` (R compilado a WebAssembly en el cliente).
* **Framework UI:** Componentes reactivos de `Shiny` integrados en Quarto.
* **Archivo Original:** `_bio-distribution.qmd` (se añade `_` para evitar que Quarto lo renderice en producción).

### 📦 Paquetes de R Requeridos (WebAssembly)
Para que este código funcione, webR descargaba dinámicamente los siguientes paquetes:
* `tidyverse` (o paquetes específicos como `dplyr`, `ggplot2` si se optimizó)
* `shiny`, `leaflet`, `sf`, `jsonlite`, (...)

 ---  

## 💡 ¿Cómo Funcionaba?

1. **Inicialización:** Al cargar la página, el navegador descargaba los binarios de webR y montaba un entorno virtual de R en segundo plano.
2. **Reactividad:** Utilizaba el servidor virtual de Shiny dentro del navegador para escuchar los cambios en los inputs (deslizadores, selectores) y re-ejecutar el código de R.
3. **Procesamiento:** Los cálculos pesados de distribución y filtrado se hacían directamente con la sintaxis nativa de R.

 ---  

## ⚠️ Limitaciones Conocidas (Motivos de la Migración)

* **Tiempo de Carga (Cold Start):** El usuario debía esperar la descarga del entorno webR y la instalación de los paquetes de R de WebAssembly antes de interactuar, a veces unos minutos.
* **Consumo de Memoria:** Mayor uso de recursos en dispositivos móviles comparado con la solución actual en JavaScript puro (OJS).

 ---  

## 🔄 Tabla de Equivalencias (Migración a OJS)

Si necesitás buscar una lógica vieja para replicarla en la versión nueva:

| Componente en R/webR | Equivalente actual en OJS |
| :--- | :--- |
| `sliderInput()`, `selectInput()` | `Inputs.range()`, `Inputs.select()` |
| `renderPlot()` / `ggplot2` | `Plot.plot()` / Observable Plot |
| Reactivos (`reactive()`, `observe()`) | Reactividad implícita de celdas OJS |
| Manipulación de datos (`dplyr`) | Funciones nativas de JS (`.filter()`, `.map()`, `.reduce()`) o `Arquero` |

### Construcción

Modelo híbrido construído mediante prompts a Claude Sonet 5 (Anthopic), Gemini de Google y Github Copilot (M.A.Ordano).
