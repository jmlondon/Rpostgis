merge.spdf <- function (x, y, by, ...) {
  y <- as.data.frame(y)
  if (missing(by)) {
    if (is.null(row.names(x@data)) || is.null(row.names(y))) {
      warning("[merge.spdf] merging by position")
      i <- 1:nrow(x@data)
    } else {
      warning("[merge.spdf] merging by row names")
      i <- row.names(x@data)
    }
  } else {
    message("[merge.spdf] merging by ", by)
    i <- match(x@data[,by], y[,by])
  }
  new_data <- data.frame(x@data, y[i,])
  row.names(new_data) <- row.names(x@data)
  if(class(x) == "SpatialPolygonsDataFrame") {
    sp::SpatialPolygonsDataFrame(geometry(x), new_data)
  }
  else if(class(x) == "SpatialPointsDataFrame") {
    sp::SpatialPointsDataFrame(geometry(x),new_data)
  }
  else if(class(x) == "SpatialLinesDataFrame") {
    sp::SpatialLinesDataFrame(geometry(x),new_data)
  }
  else {
    warning("x is not a supported spatial data frame")
  }
}
