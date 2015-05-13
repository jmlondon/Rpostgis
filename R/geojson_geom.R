# skeleton for how we might create the geojson geometries for each spatial element

geojson_geom <- function(sp.obj) {
  pts <- as.numeric(coordinates(sp.obj))
  j <- paste('{"type": "Point","coordinates": [',pts[1],',',pts[2],']}')
  return(j)
}   
