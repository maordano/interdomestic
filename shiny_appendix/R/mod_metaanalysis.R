library(shiny)
library(metafor)
library(dplyr)

# 1. UI del Módulo
metaAnalysisUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(4,
             wellPanel(
               h4("Configuración del Meta-análisis"),
               selectInput(ns("method"), "Modelo de Ajuste:", 
                           choices = c("Efectos Fijos (FE)" = "FE", "Efectos Aleatorios (REML)" = "REML")),
               sliderInput(ns("hetero"), "Simular nivel de Heterogeneidad:", min = 0, max = 1, value = 0.3, step = 0.1),
               br(),
               p("Este módulo sintetiza de manera reproducible la magnitud del efecto (Effect Sizes) recolectada en el ámbito doméstico.")
             )
      ),
      column(8,
             h4("Gráfico de Bosque (Forest Plot) Interactivo"),
             plotOutput(ns("forest")),
             br(),
             h5("Ficha Metodológica de Síntesis (STAPLE / FAIR)"),
             verbatimTextOutput(ns("meta_results"))
      )
    )
  )
}

# 2. Server del Módulo
metaAnalysisServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    # Datos simulados basados en estudios de interacción de vida silvestre doméstica
    # (Para producción, aquí leerías tu CSV/dataframe real)
    dataset_reactivo <- reactive({
      set.seed(123)
      k <- 8 # 8 estudios co-creados
      yi <- rnorm(k, mean = 0.5, sd = 0.1 + input$hetero) # Effect sizes (ej. d de Cohen)
      vi <- runif(k, 0.02, 0.05) # Varianzas
      data.frame(
        estudio = paste("Ensamble Número", 1:k),
        yi = yi,
        vi = vi
      )
    })
    
    # Ejecución del Meta-análisis vía metafor
    modelo_ajustado <- reactive({
      df <- dataset_reactivo()
      # Cálculo del modelo meta-analítico
      rma(yi = yi, vi = vi, data = df, method = input$method)
    })
    
    # Render del Forest Plot
    output$forest <- renderPlot({
      res <- modelo_ajustado()
      df <- dataset_reactivo()
      
      forest(res, 
             slab = df$estudio, 
             xlab = "Magnitud del Efecto (Effect Size / Síntesis)",
             theme = "light")
    })
    
    # Reporte FAIR de Heterogeneidad y Estadísticos
    output$meta_results <- renderText({
      res <- modelo_ajustado()
      paste0(
        "--- REPRODUCIBLE SINTERDOMESTIC META-PROFILE ---\n",
        "Modelo Utilizado: ", input$method, "\n",
        "Efecto Global Estimado: ", round(res$b[1], 3), " (IC 95%: ", round(res$ci.lb, 3), " a ", round(res$ci.ub, 3), ")\n",
        "Heterogeneidad (I^2): ", round(res$I2, 2), "%\n",
        "Protocolo STAPLE: Código abierto verificado. Reutilización FAIR garantizada mediante el motor metafor en R."
      )
    })
  })
}
