#' Get length-weight data
#'
#' @param M List object created by read_admb function
#' @return dataframe of the length-weight relationship used in the model
#' @author DN Webber
#' @export
#'
.get_length_weight_df <- function(M)
{
    n   <- length(M)
    mdf <- NULL
    for(i in 1:n)
    {
        A  <- M[[i]]
        nsex <- 1
        if (is.matrix(A$mean_wt))
        {
            nsex <- 2
            wt <- t(A$mean_wt)
        } else {
            wt <- data.frame(A$mean_wt)
        }
        colnames(wt) <- .SEX[1:nsex+1]
        df <- data.frame(Model = names(M)[i], Length = A$mid_points, wt)
        df1 <- melt(df, id.var = c("Model", "Length"))
        mdf <- rbind(mdf, df1)
    }
    names(mdf) <- c("Model", "Length", "Sex", "Weight")
    mdf$Sex <- factor(mdf$Sex, levels = sort(levels(mdf$Sex)))
    return(mdf)	
}


#' Plot length-weight relationship
#'
#' @param M list object created by read_admb function
#' @param xlab the x-axis label for the plot
#' @param ylab the y-axis label for the plot
#' @return plot of the length-weight relationship
#' @author DN Webber
#' @export
#' 
plot_length_weight <- function(M, xlab = "Size", ylab = "Weight")
{
    xlab <- paste0("\n", xlab)
    ylab <- paste0(ylab, "\n")
    mdf <- .get_length_weight_df(M)
    p <- ggplot(mdf, aes(x = Length, y = Weight)) +
        labs(x = xlab, y = ylab)
    if (length(M) == 1)
    {
        p <- p + geom_line(aes(linetype = Sex))
    } else {
        if (.OVERLAY)
        {
            p <- p + geom_line(aes(linetype = Sex, col = Model))
        } else {
            p <- p + geom_line(aes(col = Model)) + facet_wrap(~Sex)
        }
    }
    print(p + .THEME)
}
