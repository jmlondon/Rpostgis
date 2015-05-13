#' Write spatial data to a PostGIS table
#'
#' \code{dbWriteSpatial} writes a Spatial*DataFrame to a PostGIS table
#'
#' This is a function for writing spatial data directly to
#' PostgreSQL/PostGIS table from an appropriate Spatial*DataFrame.
#' The function relies on the \code{GeoJSON} format to
#' transfer the spatial data. The non-geometry columns in
#' the table are written via the \code{RPostgreSQL} package. 
#'
#' @param con A valid PostgreSQL connection (from RPostgreSQL)
#' @param spatial.df A valid Spatial*DataFrame
#' @param schemaname Schema where the target table of interest will reside
#' @param tablename Name of the target database table. 
#' @param srid SRID value to be passed to PostGIS (may not be needed)
#' @param replace Specify whether an existing table should be replaced
#'
#' @return TRUE
#'
#' @export
#'
#' @examples
#'
#' \dontrun{
#'
#' }
dbWriteSpatial <- function(con,
                           spatial.df,
                           schemaname = "public", 
                           tablename, 
                           srid = NULL, 
                           replace = FALSE) {
  
  # Extract the EPSG integer value from PROJ.4 if not given
  if (is.null(srid)) {
    srid <- str_sub(
      proj4string(spatial.df),
      start = str_locate(proj4string(spatial.df),'epsg:')[1,2] +
        1,
      end = str_locate(proj4string(spatial.df),'epsg:')[1,2] +
        4
    )
  }
  # Create well known text and add to spatial DF
  spatial.df$gjson <- NA
  for(i in 1:nrow(spatial.df)) {
    spatial.df[i,"gjson"] <- geojson_point(spatial.df[i,])
  }
  # Add temporary unique ID to spatial DF
  spatial.df$spatial_id <- 1:nrow(spatial.df)
  
  # Set column names to lower case
  names(spatial.df) <- tolower(names(spatial.df))
  names(spatial.df) <- gsub("\\.","",names(spatial.df))
  spatial.df <- as.data.frame(spatial.df)
  rv <-
    dbWriteTable(
      con, c(schemaname, tablename), spatial.df, overwrite = replace, row.names =
        FALSE
    )
  
  # Create geometry column and clean up table
  schema.table <- paste(schemaname, ".", tablename, sep = "")
  query1 <-
    paste("ALTER TABLE ", schema.table, " ADD COLUMN geom GEOMETRY;", sep =
            "")
  query2 <-
    paste("ALTER TABLE", schema.table, "ADD COLUMN objectid SERIAL PRIMARY KEY;")
  query3 <-
    paste(
      "UPDATE ", schema.table, " SET geom = ST_GeomFromGeoJSON(t.gjson) FROM ", schema.table, " t  WHERE t.spatial_id = ", schema.table, ".spatial_id;", sep =
        ""
    )
  query4 <-
    paste("ALTER TABLE", schema.table, "DROP COLUMN spatial_id;")
  query5 <- paste("ALTER TABLE", schema.table, "DROP COLUMN gjson;")
  query6 <-
    paste(
      "SELECT UpdateGeometrySRID('",schemaname,"','",tablename,"','geom',",srid,");",sep =
        ""
    )
  er <- dbGetQuery(con, statement = query1)
  er <- dbGetQuery(con, statement = query2)
  er <- dbGetQuery(con, statement = query3)
  er <- dbGetQuery(con, statement = query4)
  er <- dbGetQuery(con, statement = query5)
  er <- dbGetQuery(con, statement = query6)
  
  return(TRUE)
}
