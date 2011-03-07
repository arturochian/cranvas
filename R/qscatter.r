#source("../cranvas/load.r")
#source("api_0.1-2.R")
#source("helper.r")
#source("axes.r")
#source("shared.r")
#source("../utilities/interaction.R")
#rm(hbar)
#rm(vbar)

#' Draw a scatterplot
#'
#' @param data data.frame source
#' @param form formula in format y ~x which designates the axis
#' @param main main title for the plot
#' @param labeled whether axes should be labeled

qscatter <- function (data, form, main = NULL, labeled = TRUE) {
#############################
# internal helper functions #
#############################

############################# end internal helper functions

################################
# data processing & parameters #
################################

  ## check if an attribute exist
#  has_attr <- function(attr) {
#    attr %in% names(data)
#  }

  ## parameters for the brush
#  .brush.attr <- attr(data, '.brush.attr')
#  if (!has_attr('.brushed') || is.null(data$.brushed)) {
#    data$.brushed = FALSE
#  }

  if (length(form) != 3) {
    stop("invalid formula, requires y ~ x format")
  } else {
    .levelX <- as.character( form[[3]] )
    .levelY <- as.character(form[[2]])
  }

  ## transform the data
  df <- data.frame(data)

  ## parameters for dataRanges
  xlab <- NULL
  ylab <- NULL

  ## labels
  ylabels <- NULL
  if (labeled) {
    yid <- find_yid(data = df, colName = as.character(.levelY))
  } else {
    yid <- NA
  }

  if (!is.na(yid[1]) ) {
      ylabels <- get_axisPosY(data = df, colName = .levelY)
  }

  xlabels <- NULL
  if (labeled) {
    xid <- find_xid(data = df, colName = as.character(.levelX))
  } else {
    xid <- NA
  }

  if (!is.na(xid[1])) {
      xlabels <- get_axisPosY(data = df, colName = .levelX)
  }

  ## parameters for all layers
  if (labeled) {
  dataRanges <- c(
    make_data_ranges(range(subset(df, select = .levelX))),
    make_data_ranges(range(subset(df, select = .levelY))))

  windowRanges <- make_window_ranges(dataRanges, xlab, ylab,
    ytickmarks=ylabels, xtickmarks = xlabels, main=main)
  } else {
    dataRanges <- c(range(subset(df, select = .levelX)),
                    range(subset(df, select = .levelY)))
    windowRanges <- dataRanges
  }

  lims <- qrect(windowRanges[c(1,2)], windowRanges[c(3,4)])

  ## parameters for bglayer
  sy <- get_axisPosX(data = df, colName = .levelX)
  sx <- get_axisPosY(data = df, colName = .levelY)

  ## parameters for datalayer
  .radius <- 2
  .alpha <- 1

  ## parameters event handling
  .startBrush <- NULL
  .endBrush <- NULL
  ## whether in the brush mode
  .brush <- TRUE
  ## mouse position
  .bpos = c(NA, NA)
  ## drag start
  .bstart = c(NA, NA)
  ## move brush?
  .bmove = TRUE
   ## brush range: horizontal and vertical
  .brange = c(diff(windowRanges[c(1,2)]), diff(windowRanges[c(3,4)]))/30

  n = nrow(data)



################################ end data processing & parameters

##########
# layers #
##########
coords <- function(item, painter, exposed) {

  # grey background with grid lines
  draw_grid_with_positions_fun(painter, dataRanges, sy, sx)

  # labels as appropriate
  if (!is.na(xid[1])) {
    labels <- get_axisPosX(data = df, colName = .levelX)
#    print("x axis labels")
#    print(labels)
    draw_x_axes_with_labels_fun(painter, dataRanges,
      axisLabel=sy, labelHoriPos=sy, name=xlab)
  } else {
    draw_x_axes_with_labels_fun(painter, dataRanges,
      axisLabel=rep("",length(sy)), labelHoriPos=sy,
      name=xlab)
  }

  if (!is.na(yid[1])) {
    labels <- get_axisPosY(data = df, colName = .levelY)
    draw_y_axes_with_labels_fun(painter, dataRanges,
      axisLabel=sx, labelVertPos=sx, name=ylab)
  } else {
    draw_y_axes_with_labels_fun(painter, dataRanges,
       axisLabel=rep("",length(sx)), labelVertPos=sx,
       name=ylab)
  }

}

scatter.all <- function(item, painter, exposed) {
  x <- subset(df, select = .levelX)[,1]
  y <- subset(df, select = .levelY)[,1]
	fill <- data$.color
	stroke <- data$.color
	
  radius <- .radius
  qdrawCircle(painter, x = x, y = y, r = radius, fill = fill, stroke = stroke)
}

brush_draw <- function(item, painter, exposed) {
    df <- as.data.frame(data)
    .brushed = data$.brushed
    if(.brush) {
        if (!any(is.na(.bpos))) {
            qlineWidth(painter) = brush(data)$size
            ##qdash(painter)=c(1,3,1,3)
            qdrawRect(painter, .bpos[1] - .brange[1], .bpos[2] - .brange[2],
                      .bpos[1] + .brange[1], .bpos[2] + .brange[2],
                      stroke = brush(data)$color)
        }

        hdata <- subset(df, .brushed)

        if (nrow(hdata) > 0) {
            ## draw the brush rectangle
            if (!any(is.na(.bpos))) {
                qlineWidth(painter) = brush(data)$size
                ##qdash(painter)=c(1,3,1,3)
                qdrawRect(painter, .bpos[1] - .brange[1], .bpos[2] - .brange[2],
                          .bpos[1] + .brange[1], .bpos[2] + .brange[2],
                      		stroke = brush(data)$color)
            }
            ## (re)draw brushed data points
            x <- subset(hdata, select = .levelX)[,1]
            y <- subset(hdata, select = .levelY)[,1]
            fill = brush(data)$color
            stroke = brush(data)$color
            radius <- .radius

            qdrawCircle( painter, x = x, y = y, r = radius, fill = fill, stroke = stroke)
        }
    }
}
########## end layers

####################
## event handlers ##
####################

keyPressFun <- function(item, event, ...) {
    key <- event$key()

    if (key == Qt$Qt$Key_Up) {        # arrow up
		.radius <<- .radius+1
        qupdate(datalayer)
		qupdate(brushlayer)
    } else if (key == Qt$Qt$Key_Down & .radius > 0) {        # arrow down
        .radius <<- .radius - 1
        qupdate(datalayer)
		qupdate(datalayer)
    } else if (key == Qt$Qt$Key_Right & .alpha < 1) {        # arrow right
	# increase alpha blending
        .alpha <<- 1.1*.alpha
        datalayer$setOpacity(.alpha)
#		brushlayer$setOpacity(.alpha)
        qupdate(datalayer)
    } else if (key == Qt$Qt$Key_Left & .alpha > 1.0/n) {        # arrow left
	# decrease alpha blending
        .alpha <<- 0.9*.alpha 
        datalayer$setOpacity(.alpha)
#		brushlayer$setOpacity(.alpha)
        qupdate(datalayer)
    }


  }

  ## record the coordinates of the mouse on click
  brush_mouse_press = function(item, event) {
      .bstart <<- as.numeric(event$pos())
      ## on right click, we can resize the brush; left click: only move the brush
      if (event$button() == Qt$Qt$RightButton) {
          .bmove <<- FALSE
      }
      if (event$button() == Qt$Qt$LeftButton) {
          .bmove <<- TRUE
      }
  }

  identify_mouse_move = function(layer, event) {
      pos = event$pos()
      .bpos <<- as.numeric(pos)
      ## simple click: don't change .brange
      if (!all(.bpos == .bstart) && (!.bmove)) {
          .brange <<- .bpos - .bstart
      }
      .new.brushed = rep(FALSE, n)
		xrange <- .radius/root$size$width()*diff(windowRanges[c(1,2)])
		yrange <- .radius/root$size$height()*diff(windowRanges[c(3,4)])
#
			rect = qrect(matrix(c(.bpos - .brange - c(xrange, yrange), 
													  .bpos + .brange + c(xrange, yrange)), 
									 2, byrow = TRUE))
#browser()									 
#			rect = qrect(matrix(c(.bpos - .brange, .bpos + .brange), 2, byrow = TRUE))
			hits = layer$locate(rect) + 1
 			
      .new.brushed[hits] = TRUE
      data$.brushed = mode_selection(data$.brushed, .new.brushed, mode = brush(data)$mode)
  }

  # Display category information on hover (query) ----------------------------
  .queryPos <- NULL

  query_draw <- function(item, painter, exposed, ...) {
    if (is.null(.queryPos)) return()

    xpos <- .queryPos[1]
    ypos <- .queryPos[2]

		xrange <- .radius/root$size$width()*diff(windowRanges[c(1,2)])
		yrange <- .radius/root$size$height()*diff(windowRanges[c(3,4)])
#		print(xrange)
#		print(yrange)
 		rect = qrect(matrix(c(xpos-xrange,ypos-yrange,xpos+xrange, ypos+yrange), 2, byrow = TRUE))
		hits = datalayer$locate(rect) + 1
#print(hits)
#print(.queryPos)
#browser()
    # Nothing under mouse?
    if (length(hits)==0) return()

    info <- as.data.frame(data[hits, c(.levelX, .levelY)])
#browser()
    
    # Nothing under mouse
#    if (nrow(info) == 0) return()

    # Work out label text
    idx <- names(info)
    infodata <- as.character(unlist(info[1,idx]))
    infostring <- paste(idx, infodata,collapse="\n", sep=": ")

    bgwidth = qstrWidth(painter, infostring)
    bgheight = qstrHeight(painter, infostring)    
    
		## adjust drawing directions when close to the boundary
		hflag = windowRanges[2] - xpos > bgwidth
		vflag = ypos - windowRanges[3] > bgheight
		qdrawRect(painter, xpos, ypos,
							xpos + ifelse(hflag, 1, -1) * bgwidth,
							ypos + ifelse(vflag, -1, 1) * bgheight,
							stroke = rgb(1, 1, 1, 0.5), fill = rgb(1, 1, 1, 0.5))

		qstrokeColor(painter) = brush(data)$label.color
    qdrawText(painter, infostring, xpos, ypos,
    	halign = ifelse(hflag, "left", "right"),
      valign = ifelse(vflag, "top", "bottom"))

  }

  query_hover <- function(item, event, ...) {
#    if (.brush) return()

    .queryPos <<- as.numeric(event$pos())
    qupdate(querylayer)
  }

  query_hover_leave <- function(item, event, ...) {
    .queryPos <<- NULL
    qupdate(querylayer)
  }

########## end event handlers

###################
# draw the canvas #
###################
  size <- qsize(as.integer(c(600, 400)))
  limits <- qrect(c(0,1), c(0,1))
  scene <- qscene()
  root <- qlayer(scene)
  root$setGeometry(qrect(0, 0, 600, 400))
  bglayer <- qlayer(parent = root, paintFun = coords, limits=lims)
  datalayer <- qlayer(parent = root, paintFun = scatter.all, keyPressFun = keyPressFun,
                         mouseMove = identify_mouse_move,
                         mousePressFun = brush_mouse_press,
                         mouseReleaseFun = identify_mouse_move, limits = lims)
  brushlayer <- qlayer(parent = root, paintFun = brush_draw, limits = lims)
  querylayer = qlayer(parent = root, query_draw, limits = lims, clip = FALSE,
    hoverMoveFun = query_hover, hoverLeaveFun = query_hover_leave)
  view <- qplotView(scene = scene)
  view$setWindowTitle(extract.formula(form))
 # view$setMaximumSize(plot1$size)

######################
# add some listeners #
######################
  if (is.mutaframe(data)) {
    func <- function(i,j) {
      if (j == ".brushed") {
        qupdate(brushlayer)
      }
    }

	  add_listener(data, func)
  }

  return(view)

}
