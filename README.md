Rpostgis
========

A package for import/export of spatial data from PostGIS
--------------------------------------------------------

`Rpostgis` provides simple access to PostgreSQL/PostGIS spatial databases without the need to build the `rgdal` packages from source (pre-built binaries on CRAN are not built against the PostgreSQL/PostGIS libraries). Initially, the focus of this package is on reading and writing data, but further development for various spatial functions could be considered.

``` r
library(RPostgreSQL)
library(sp)
library(rgdal)
library(Rpostgis)

# username, password and database IP stored 
# within .Rprofile as options
pg_usr <- getOption('pg_usr')
pg_pwd <- getOption('pg_pwd')
pg_ip <- getOption('pg_ip')

# create the string to use for connecting via rgdal
pg_string <- paste('PG:dbname=pg',
                   'host=',pg_ip,
                   'user=',pg_usr,
                   'password=',pg_pwd)

# create connection via RPostgreSQL
con = RPostgreSQL::dbConnect(
  dbDriver("PostgreSQL"), dbname="pg", host=pg_ip, port="5432", 
  user=pg_usr, password=pg_pwd
)

# load the meuse dataset from the sp package
data(meuse)
coordinates(meuse) <- ~x+y
proj4string(meuse) <- CRS("+init=epsg:28992")

# save the meuse dataset to PostgreSQL/PostGIS via rgdal
# (dbWriteSpatial function still not complete)

rgdal::writeOGR(meuse, pg_string, layer="meuse",
         driver="PostgreSQL",
         layer_options = c("geometry_name=geom","fid=objectid")
)

# now lets read it back, but using dbReadSpatial instead of rgdal
meuse.out <- Rpostgis::dbReadSpatial(con,schemaname="public",tablename="meuse",
                           geomcol="geom",idcol="objectid")
```
