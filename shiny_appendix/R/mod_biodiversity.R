library(shiny)
library(leaflet)
library(dplyr)
library(rgbif)

# 1. UI del Módulo con Referencias de Color Nativas
biodiversityUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(4,
             wellPanel(
               h4("Control de Especies"),
               br(),
               
               # Entrada Especie A con Círculo Azul como Referencia
               tags$div(
                 style = "margin-bottom: 15px;",
                 tags$label(
                   style = "display: flex; align-items: center; font-weight: bold; margin-bottom: 5px;",
                   tags$span(style = "display: inline-block; width: 12px; height: 12px; background-color: #2563eb; border-radius: 50%; margin-right: 8px;"),
                   "Especie A (Científico):"
                 ),
                 textInput(ns("sp1"), label = NULL, value = "Panthera onca")
               ),
               
               # Entrada Especie B con Círculo Rojo como Referencia
               tags$div(
                 style = "margin-bottom: 15px;",
                 tags$label(
                   style = "display: flex; align-items: center; font-weight: bold; margin-bottom: 5px;",
                   tags$span(style = "display: inline-block; width: 12px; height: 12px; background-color: #dc2626; border-radius: 50%; margin-right: 8px;"),
                   "Especie B (Científico):"
                 ),
                 textInput(ns("sp2"), label = NULL, value = "Puma concolor")
               ),
               
               numericInput(ns("max_reg"), "Registros máximos por especie:", 100, min = 10),
               br(),
               actionButton(ns("run"), "Sincronizar Ecosistemas", class = "btn-primary", style = "width: 100%;")
             )
      ),
      column(8,
             leafletOutput(ns("map"), height = "450px"),
             br(),
             h5("Ficha Darwin Core / CARE Atribución"),
             verbatimTextOutput(ns("metadata"))
      )
    )
  )
}

# 2. Server del Módulo - Solución Definitiva de Asignación Cromática por Fila
biodiversityServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    datos <- eventReactive(input$run, {
      req(input$sp1, input$sp2)
      
      # Descarga de datos desde GBIF
      occ1 <- occ_search(scientificName = input$sp1, limit = input$max_reg, hasCoordinate = TRUE)$data
      occ2 <- occ_search(scientificName = input$sp2, limit = input$max_reg, hasCoordinate = TRUE)$data
      
      df1 <- if(!is.null(occ1) && "decimalLatitude" %in% colnames(occ1)) occ1 %>% select(decimalLatitude, decimalLongitude, scientificName, datasetKey) else NULL
      df2 <- if(!is.null(occ2) && "decimalLatitude" %in% colnames(occ2)) occ2 %>% select(decimalLatitude, decimalLongitude, scientificName, datasetKey) else NULL
      
      bind_rows(df1, df2)
    })
    
    output$map <- renderLeaflet({
      df <- datos()
      
      # 1. Inicialización del mapa base con grilla de paralelos/meridianos limpia
      m <- leaflet() %>%
        addTiles() %>%
        addSimpleGraticule(interval = 10)
      
      if (is.null(df) || nrow(df) == 0) {
        return(m %>% setView(lng = 0, lat = 0, zoom = 2))
      }
      
      # 2. Limpieza de textos para la comparación interactiva
      sp1_clean <- trimws(tolower(input$sp1))
      sp2_clean <- trimws(tolower(input$sp2))
      
      # 3. Inyección del color fila por fila dentro del dataframe (Método Seguro)
      df_color <- df %>%
        mutate(color_asignado = case_when(
          grepl(sp1_clean, tolower(scientificName), fixed = TRUE) ~ "#2563eb", # Azul Especie A
          grepl(sp2_clean, tolower(scientificName), fixed = TRUE) ~ "#dc2626", # Rojo Especie B
          TRUE ~ "#64748b" # Gris de respaldo
        ))
      
      # 4. Renderizado mapeando el color nativo del dataframe usando la virgulilla (~)
      m %>%
        addCircleMarkers(
          data = df_color,
          lng = ~decimalLongitude, lat = ~decimalLatitude,
          color = ~color_asignado, # La virgulilla fuerza a Leaflet a leer la columna fila por fila
          radius = 6,
          stroke = TRUE,
          weight = 1,
          fillOpacity = 0.7,
          popup = ~paste("<strong>Especie:</strong>", scientificName, "<br><strong>Dataset:</strong>", datasetKey)
        )
    })
    
    output$metadata <- renderText({
      df <- datos()
      req(df)
      datasets_citados <- unique(df$datasetKey)
      paste0(
        "--- INTERDOMESTIC METADATA PROFILE (FAIR/CARE) ---\n",
        "Estándar Semántico: Darwin Core (DwC)\n",
        "Orígenes de datos web vinculados (GBIF ID): ", length(datasets_citados), " datasets únicos.\n",
        "Protocolo Ético CARE: Atribución obligatoria a las comunidades proveedoras primarias."
      )
    })
  })
}
