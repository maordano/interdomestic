library(shiny)
#library(leaflet)
library(dplyr)
#library(rgbif)
library(metafor)

# 1. Cargar obligatoriamente los módulos (Paths relativos)
source("R/mod_biodiversity.R")
source("R/mod_metaanalysis.R")

# 2. Configurar la Interfaz unificada
ui <- fluidPage(
  theme = bslib::bs_theme(version = 5, bootswatch = "minty"), # Estética limpia y moderna
  
  titlePanel("interdomestic ~ Repositorio Dinámico de Resultados"),
  br(),
  
  tabsetPanel(
    tabPanel("🗺️ Distribución de Especies (GBIF / CARE)", 
             br(), 
             biodiversityUI("bio_module")
    ),
    tabPanel("📊 Síntesis de Effect Sizes (Metafor / STAPLE)", 
             br(), 
             metaAnalysisUI("meta_module")
    )
  )
)

# 3. Lógica del Servidor central
server <- function(input, output, session) {
  # Ejecutamos las instancias de los módulos de forma independiente
  biodiversityServer("bio_module")
  metaAnalysisServer("meta_module")
}

# 4. Lanzar la aplicación
shinyApp(ui = ui, server = server)
