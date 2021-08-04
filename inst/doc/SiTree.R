## -----------------------------------------------------------------------------
library(sitree)
head(tr)

head(fl)


## -----------------------------------------------------------------------------
prep.common.vars.fun



## -----------------------------------------------------------------------------
result.sitree <- sitree (tree.df   = stand.west.tr,
                           stand.df  = stand.west.st,
                           functions = list(
                             fn.growth     = 'grow.dbhinc.hgtinc',
                             fn.mort       = 'mort.B2007',
                             fn.recr       = 'recr.BBG2008',
                             fn.management = NULL,
                             fn.tree.removal = NULL,
                             fn.modif      = NULL, 
                             fn.prep.common.vars = 'prep.common.vars.fun'
                           ),
                           n.periods = 12,
                           period.length = 5,
                           mng.options = NA,
                           print.comments = FALSE,
                           fn.dbh.inc    = 'dbhi.BN2009',
                           fn.hgt.inc    = 'height.korf'
                         )
str(result.sitree$live)
head(sitree2dataframe(result.sitree$live))

