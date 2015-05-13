#' Read spatial data from a PostGIS table
#'
#' \code{dbReadSpatial} returns a Spatial*DataFrame
#'
#' This is a function for reading spatial data directly from a
#' PostgreSQL/PostGIS table and returning the appropriate Spatial*DataFrame.
#' The function relies on the \code{ST_AsGeoJSON} function with PostGIS to
#' return the spatial data as a GeoJSON object. The non-geometry columns in
#' the table are read via the \code{RPostgreSQL} package.
#'
#' @param con A valid PostgreSQL connection (from RPostgreSQL)
#' @param schemaname Schema where the specified table of interest resides
#' @param tablename Name of the database table. must contain a single
#'  geometry column
#' @param geomcol Name of the geometry column in the specified table (target
#'  table may not have more than one geometry column!) defaults to the
#'  standard 'geom'
#' @param idcol Name of the column with unique IDs. This usually corresponds
#'  to the specified primary key.
#'
#' @return A Spatial Data Frame object
#'
#' @export
#'
#' @examples
#'
#' \dontrun{
#'
#' }
dbReadSpatial <-
  function(con, schemaname = "public", tablename, geomcol = "geom", idcol =
             NULL) {
    ## Build query and fetch the target table
    # Get column names
    q.res <-RPostgreSQL::dbSendQuery(
        con, statement = paste(
          "SELECT column_name FROM information_schema.columns WHERE table_name ='", 
          tablename,
          "' AND table_schema ='",
          schemaname,
          "';", sep =
            "")
      )
    schema.table = paste(schemaname, ".", tablename, sep = "")
    q.df <- RPostgreSQL::fetch(q.res,-1)
    # Some safe programming
    if (!(geomcol %in% q.df[,1])) {
      stop(paste("No", geomcol, "column in specified table."))
    }
    if (!is.null(idcol)) {
      if (!(idcol %in% q.df[,1])) {
        stop(paste("Specified idname '", idcol, "' not found.", sep = ""))
      }
    }
    # Get table data, minus geomcol
    query <-
      paste("SELECT", paste(q.df[,1][q.df[,1] != geomcol], collapse = ", "),
            paste("FROM ", schema.table,";",sep = ""))
    t.res <- RPostgreSQL::dbSendQuery(con, statement = query)
    t.df <- RPostgreSQL::fetch(t.res,-1)
    
    ## Get srid and create proj4 string
    srid <- RPostgreSQL::dbGetQuery(
      conn,
      paste(
        "SELECT Find_SRID('",schemaname,"', '",tablename,"', '",geomcol,"');",sep =
          ""
      )
    )
    p4s <- paste("+init=epsg:",srid[1,],sep = "")
    
    ## Get spatial data via geojson
    res <- RPostgreSQL::dbGetQuery(
      con,
      paste(
        "SELECT row_to_json(fc)::text geojson_text ",
        "FROM ( ",
        "SELECT 'FeatureCollection' As type, ",
        "array_to_json(array_agg(f)) As features ",
        "FROM (SELECT 'Feature' As type, ",
        "ST_AsGeoJSON(lg.",geomcol,")::json As geometry, ",
        "row_to_json(lp) As properties ",
        "FROM ",schema.table," As lg ",
        "INNER JOIN (SELECT ",idcol," FROM ",schema.table,") As lp ",
        "ON lg.",idcol," = lp.",idcol,") As f )  As fc;",sep =
          ""
      )
    )
    
    down.spdf <-
      rgdal::readOGR(res$geojson_text, "OGRGeoJSON", verbose = F, p4s = p4s)
    spatial.df <- merge.spdf(down.spdf,t.df,by = idcol)
    
    return(spatial.df)
  }
