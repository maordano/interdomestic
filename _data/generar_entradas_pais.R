# =============================================================================
# generar_entradas_pais.R
# interdomestic — Generador semiautomático de entradas para governance_db.json
# -----------------------------------------------------------------------------
# Qué hace:
#   Dado un pequeño listado de países (nombre + códigos ISO2/ISO3 + continente
#   + hemisferio), genera automáticamente las entradas que SÍ siguen un patrón
#   de URL confiable (Leyes vía FAOLEX, Libro Rojo aproximado vía API GBIF) y
#   deja placeholders explícitos para las que requieren curaduría manual
#   (Gubernamental y Nombres Comunes).
#
# Qué NO hace:
#   No verifica que los enlaces "manuales" sigan vigentes, ni completa por vos
#   los nombres comunes o el ministerio correspondiente: eso queda a tu criterio
#   de curaduría situada (principio CARE: la calidad de la fuente prima sobre
#   la automatización total).
#
# Uso:
#   1. Completá el data.frame `nuevos_paises` de abajo.
#   2. Corré el script. Va a imprimir un bloque JSON en consola y también
#      guardarlo en nuevas_entradas.json
#   3. Revisá manualmente los campos "Gubernamental" y "Nombres Comunes"
#      (llevan "PENDIENTE" y curaduria: "manual_pendiente").
#   4. Pegá/mergeá el resultado dentro de governance_db.json.
# =============================================================================

library(jsonlite)

# -----------------------------------------------------------------------------
# 1. Completá acá los países nuevos que querés incorporar
#    (buscá los códigos ISO 3166-1 alpha-2 / alpha-3 en https://www.iso.org/obp/ui/)
# -----------------------------------------------------------------------------
nuevos_paises <- data.frame(
  pais        = c("Ecuador", "Bolivia"),
  iso2        = c("EC", "BO"),
  iso3        = c("ECU", "BOL"),
  continente  = c("América", "América"),
  hemisferio  = c("Sur", "Sur"),
  url_gob     = c("https://www.ambiente.gob.ec", "https://www.madrudp.gob.bo"),
  nombre_gob  = c("Ministerio del Ambiente, Agua y Transición Ecológica",
                  "Ministerio de Medio Ambiente y Agua"),
  stringsAsFactors = FALSE
)

# -----------------------------------------------------------------------------
# 2. Construcción de entradas
# -----------------------------------------------------------------------------
construir_entradas <- function(fila) {
  list(
    # --- MANUAL: Gubernamental (verificar vigencia antes de publicar) ---
    list(
      pais = fila$pais, tipo = "Gubernamental", recurso = fila$nombre_gob,
      url = fila$url_gob,
      descripcion = "Autoridad nacional de aplicación en política ambiental y vida silvestre. [VERIFICAR VIGENCIA DEL ENLACE]",
      continente = fila$continente, hemisferio = fila$hemisferio,
      curaduria = "manual"
    ),
    # --- PLANTILLA ISO3: Leyes vía FAOLEX (FAO) ---
    list(
      pais = fila$pais, tipo = "Leyes",
      recurso = paste0("FAOLEX — Perfil legislativo de ", fila$pais, " (FAO)"),
      url = paste0("https://www.fao.org/faolex/country-profiles/general-profile/en/?iso3=", fila$iso3),
      descripcion = "Repositorio comparado de legislación nacional sobre fauna silvestre, ecosistemas y recursos naturales, indexado por FAO.",
      continente = fila$continente, hemisferio = fila$hemisferio,
      curaduria = "plantilla_iso3"
    ),
    # --- PLANTILLA ISO2 (provisoria): Libro Rojo aproximado vía API GBIF ---
    list(
      pais = fila$pais, tipo = "Libro Rojo",
      recurso = paste0("GBIF — Ocurrencias con categoría IUCN en ", fila$pais, " (aproximado)"),
      url = paste0("https://api.gbif.org/v1/occurrence/search?country=", fila$iso2, "&iucnRedListCategory=CR,EN,VU"),
      descripcion = "Consulta programática (API JSON) de registros con categoría de amenaza IUCN (CR/EN/VU) filtrados por país. Usar como capa provisoria hasta incorporar el Libro Rojo nacional oficial cuando exista.",
      continente = fila$continente, hemisferio = fila$hemisferio,
      curaduria = "plantilla_iso2_provisoria"
    ),
    # --- MANUAL PENDIENTE: Nombres Comunes ---
    list(
      pais = fila$pais, tipo = "Nombres Comunes",
      recurso = paste0("[PENDIENTE] Nomenclador de nombres vernáculos de ", fila$pais),
      url = "",
      descripcion = "PENDIENTE DE CURADURIA MANUAL: buscar checklist taxonómico nacional o portal de biodiversidad local con nombres comunes.",
      continente = fila$continente, hemisferio = fila$hemisferio,
      curaduria = "manual_pendiente"
    )
  )
}

entradas <- unlist(
  lapply(seq_len(nrow(nuevos_paises)), function(i) construir_entradas(nuevos_paises[i, ])),
  recursive = FALSE
)

# -----------------------------------------------------------------------------
# 3. Exportar JSON (revisar antes de mergear con governance_db.json)
# -----------------------------------------------------------------------------
json_salida <- toJSON(entradas, auto_unbox = TRUE, pretty = TRUE)
write(json_salida, "nuevas_entradas.json")
cat(json_salida)

# -----------------------------------------------------------------------------
# 4. (Opcional) Merge automático directo en governance_db.json
#    Descomentar si querés que el script haga el append por vos.
# -----------------------------------------------------------------------------
# ruta_db <- "../_data/governance_db.json"
# db_actual <- fromJSON(ruta_db, simplifyDataFrame = FALSE)
# db_actualizado <- c(db_actual, entradas)
# write(toJSON(db_actualizado, auto_unbox = TRUE, pretty = TRUE), ruta_db)
