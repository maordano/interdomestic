library(shiny)
library(leaflet)
library(dplyr)
library(rgbif)

# 1. UI del Módulo
biodiversityUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(4,
             wellPanel(
               textInput(ns("sp1"), "Especie A (Científico):", "Panthera onca"),
               textInput(ns("sp2"), "Especie B (Científico):", "Puma concolor"),
               numericInput(ns("max_reg"), "Registros máx:", 100, min = 10),
               actionButton(ns("run"), "Sincronizar Ecosistemas", class = "btn-primary")
             )
      ),
      column(8,
             leafletOutput(ns("map"), height = "400px"),
             br(),
             h5("Ficha Darwin Core / CARE Atribución"),
             verbatimTextOutput(ns("metadata"))
      )
    )
  )
}

# 2. Server del Módulo
biodiversityServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    # Descarga reactiva de datos web (GBIF)
    datos <- eventReactive(input$run, {
      req(input$sp1, input$sp2)
      
      # Descarga paralela simulada para simplificar
      occ1 <- occ_search(scientificName = input$sp1, limit = input$max_reg, hasCoordinate = TRUE)$data
      occ2 <- occ_search(scientificName = input$sp2, limit = input$max_reg, hasCoordinate = TRUE)$data
      
      # Estandarización mínima Darwin Core (FAIR)
      df1 <- if(!is.null(occ1)) occ1 %>% select(decimalLatitude, decimalLongitude, scientificName, datasetKey) else NULL
      df2 <- if(!is.null(occ2)) occ2 %>% select(decimalLatitude, decimalLongitude, scientificName, datasetKey) else NULL
      
      bind_rows(df1, df2)
    })
    
    output$map <- renderLeaflet({
      df <- datos()
      req(df)
      leaflet(df) %>%
        addTiles() %>%
        addCircleMarkers(
          lng = ~decimalLongitude, lat = ~decimalLatitude,
          color = ifelse(df$scientificName == input$sp1, "blue", "red"),
          popup = ~paste("Especie:", scientificName, "<br>Dataset Key:", datasetKey)
        )
    })
    
    output$metadata <- renderText({
      df <- datos()
      req(df)
      datasets_citados <- unique(df$datasetKey)
      paste0(
        "--- INTERDOMESTIC METADATA PROFILE (FAIR/CARE) ---\n",
        "Estándar Semántico: Darwin Core (DwC)\n",
        "Orígenes de datos web vinculados (GBIF ID/DOIs): ", length(datasets_citados), " datasets únicos.\n",
        "Protocolo Ético CARE: Atribución obligatoria a las comunidades proveedoras listadas en los metadatos del datasetKey."
      )
    })
  })
}
