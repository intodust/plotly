#' Initiate a plotly visualization
#'
#' Transform data into a plotly visualization.
#' 
#' There are a number of "visual properties" that aren't included in the officical 
#' Reference section (see below). 
#' 
#' @param data A data frame (optional).
#' @param ... These arguments are documented at \url{https://plot.ly/r/reference/}
#' Note that acceptable arguments depend on the value of \code{type}.
#' @param type A character string describing the type of trace.
#' @param color A formula containing a name or expression. 
#' Values are scaled and mapped to color codes based on the value of 
#' \code{colors} and \code{alpha}. To avoid scaling, wrap with \code{\link{I}()},
#' and provide value(s) that can be converted to rgb color codes by 
#' \code{\link[grDevices]{col2rgb}()}.
#' @param colors Either a colorbrewer2.org palette name (e.g. "YlOrRd" or "Blues"), 
#' or a vector of colors to interpolate in hexadecimal "#RRGGBB" format, 
#' or a color interpolation function like \code{colorRamp()}.
#' @param alpha A number between 0 and 1 specifying the alpha channel applied to color.
#' @param symbol A formula containing a name or expression. 
#' Values are scaled and mapped to symbols based on the value of \code{symbols}.
#' To avoid scaling, wrap with \code{\link{I}()}, and provide valid 
#' \code{\link{pch}()} values and/or valid plotly symbol(s) as a string
#' @param symbols A character vector of symbol types. 
#' Either valid \link{pch} or plotly symbol codes may be supplied.
#' @param linetype A formula containing a name or expression. 
#' Values are scaled and mapped to linetypes based on the value of 
#' \code{linetypes}. To avoid scaling, wrap with \code{\link{I}()}.
#' @param linetypes A character vector of line types. 
#' Either valid \link{par} (lty) or plotly dash codes may be supplied.
#' @param size A variable name or numeric vector to encode the size of markers.
#' @param sizes A numeric vector of length 2 used to scale sizes to pixels.
#' @param width	Width in pixels (optional, defaults to automatic sizing).
#' @param height Height in pixels (optional, defaults to automatic sizing).
#' @param source Only relevant for \link{event_data}.
#' @seealso \code{\link{layout}()}, \code{\link{add_trace}()}, \code{\link{style}()}
#' @author Carson Sievert
#' @export
#' @examples
#' \dontrun{
#' 
#' # plot_ly() tries to create a sensible plot based on the information you 
#' # give it. If you don't provide a trace type, plot_ly() will infer one.
#' plot_ly(economics, x = ~pop)
#' plot_ly(economics, x = ~date, y = ~pop)
#' # plot_ly() doesn't require data frame(s), which allows one to take 
#' # advantage of trace type(s) designed specifically for numeric matrices
#' plot_ly(z = ~volcano)
#' plot_ly(z = ~volcano, type = "surface")
#' 
#' # plotly has a functional interface: every plotly function takes a plotly
#' # object as it's first input argument and returns a modified plotly object
#' add_lines(plot_ly(economics, x = ~date, y = ~unemploy/pop))
#' 
#' # To make code more readable, plotly imports the pipe operator from magrittr
#' economics %>% plot_ly(x = ~date, y = ~unemploy/pop) %>% add_lines()
#' 
#' # Attributes defined via plot_ly() set 'global' attributes that 
#' # are carried onto subsequent traces, but those may be over-written
#' plot_ly(economics, x = ~date, color = I("black")) %>%
#'  add_lines(y = ~uempmed) %>%
#'  add_lines(y = ~psavert, color = I("red"))
#' 
#' # Attributes are documented in the figure reference -> https://plot.ly/r/reference
#' # You might notice plot_ly() has named arguments that aren't in this figure
#' # reference. These arguments make it easier to map abstract data values to
#' # visual attributes.
#' p <- plot_ly(iris, x = ~Sepal.Width, y = ~Sepal.Length) 
#' add_markers(p, color = ~Petal.Length, size = ~Petal.Length)
#' add_markers(p, color = ~Species)
#' add_markers(p, color = ~Species, colors = "Set1")
#' add_markers(p, symbol = ~Species)
#' add_paths(p, linetype = ~Species)
#' 
#' }
#' 
plot_ly <- function(data = data.frame(), ..., type = NULL, 
                    color, colors = NULL, alpha = 1, symbol, symbols = NULL, 
                    size, sizes = c(10, 100), linetype, linetypes = NULL,
                    width = NULL, height = NULL, source = "A") {
  if (!is.data.frame(data)) {
    stop("First argument, `data`, must be a data frame.", call. = FALSE)
  }
  # "native" plotly arguments
  attrs <- list(...)
  
  # warn about old arguments that are no longer supported
  for (i in c("filename", "fileopt", "world_readable")) {
    if (is.null(attrs[[i]])) next
    warning("Ignoring ", i, ". Use `plotly_POST()` if you want to post figures to plotly.")
    attrs[[i]] <- NULL
  }
  if (!is.null(attrs[["group"]])) {
    warning(
      "The group argument has been deprecated. Use `group_by()` instead.\n",
      "See `help('plotly_data')` for examples"
    )
    attrs[["group"]] <- NULL
  }
  if (!is.null(attrs[["inherit"]])) {
    warning("The inherit argument has been deprecated.")
    attrs[["inherit"]] <- NULL
  }
  
  # tack on "special" arguments
  attrs$color <- if (!missing(color)) color
  attrs$symbol <- if (!missing(symbol)) symbol
  attrs$linetype <- if (!missing(linetype)) linetype
  attrs$size <- if (!missing(size)) size
  
  attrs$colors <- colors
  attrs$alpha <- alpha
  attrs$symbols <- symbols
  attrs$linetypes <- linetypes
  attrs$sizes <- sizes
  attrs$type <- type
  
  # id for tracking attribute mappings and finding the most current data
  id <- new_id()
  # avoid weird naming clashes
  plotlyVisDat <- data
  p <- list(
    visdat = setNames(list(function() plotlyVisDat), id),
    cur_data = id,
    attrs = setNames(list(attrs), id),
    # we always deal with a _list_ of traces and _list_ of layouts 
    # since they can each have different data
    layout = list(
        width = width, 
        height = height,
        # sane margin defaults (mainly for RStudio)
        margin = list(b = 40, l = 60, t = 25, r = 10)
    ),
    config = list(modeBarButtonsToRemove = I("sendDataToCloud")),
    base_url = get_domain(),
    # TODO: make this trace specific when we merge with crosstalk branch
    source = source
  )
  
  as_widget(p)
}


#' Initiate a plotly-mapbox object
#' 
#' Use this function instead of \code{\link{plot_ly}()} to initialize
#' a plotly-mapbox object. This enforces the entire plot so use
#' the scattermapbox trace type, and enables higher level geometries
#' like \code{\link{add_polygons}()} to work
#' 
#' @param ... arguments passed along to \code{\link{plot_ly}()}. They should be
#' valid scattermapbox attributes - \url{https://plot.ly/r/reference/#scattermapbox}.
#' Note that x/y can also be used in place of lat/lon.
#' @export
#' @examples \dontrun{
#' 
#' map_data("world", "canada") %>%
#'   group_by(group) %>%
#'   mapbox(x = ~lat, y = ~long) %>%
#'   add_polygons() %>%
#'   layout(
#'     mapbox = list(
#'       center = list(lat = ~median(lat), lon = ~median(long))
#'     )
#'   )
#' }
#' 
mapbox <- function(data = data.frame(), ...) {
  p <- plot_ly(data, ...)
  p <- config(p, mapboxAccessToken = mapbox_token())
  p$x$mapType <- "mapbox"
  p
}

#' Initiate a plotly-geo object
#' 
#' Use this function instead of \code{\link{plot_ly}()} to initialize
#' a plotly-geo object. This enforces the entire plot so use
#' the scattergeo trace type, and enables higher level geometries
#' like \code{\link{add_polygons}()} to work
#' 
#' @param ... arguments passed along to \code{\link{plot_ly}()}.
#' @export
#' @examples
#' 
#' map_data("world", "canada") %>%
#'   group_by(group) %>%
#'   geo(x = ~lat, y = ~long) %>%
#'   add_polygons()
#' 
geo <- function(data = data.frame(), ...) {
  p <- plot_ly(data, ...)
  p$x$mapType <- "geo"
  p
}


#' Convert a list to a plotly htmlwidget object
#' 
#' @param x a plotly object.
#' @param ... other options passed onto \code{htmlwidgets::createWidget}
#' @export
#' @examples 
#' 
#' trace <- list(x = 1, y = 1)
#' obj <- list(data = list(trace), layout = list(title = "my plot"))
#' as_widget(obj)
#' 

as_widget <- function(x, ...) {
  if (inherits(x, "htmlwidget")) return(x)
  # add plotly class mainly for printing method
  # customize the JSON serializer (for htmlwidgets)
  attr(x, 'TOJSON_FUNC') <- to_JSON
  htmlwidgets::createWidget(
    name = "plotly",
    x = x,
    width = x$layout$width,
    height = x$layout$height,
    sizingPolicy = htmlwidgets::sizingPolicy(
      browser.fill = TRUE,
      defaultWidth = '100%',
      defaultHeight = 400
    ),
    preRenderHook = plotly_build
  )
}
