## -----------------------------------------------------------------------------
## Always bare in mind that RF trList and trListDead are modified in place
## Do not copy 

Polygon <- setRefClass("Polygon", fields = c("sides"))
square <- Polygon$new(sides = 4)

square.to.triangle <- function(a){
  ## This makes the object triangle point to square, it does not create a copy
  ## since square is a RC object
  triangle <- square
  ## when we modifiy triangle we are modifying square.
  triangle$sides <- 3
  return(a+2)
}

## square has 4 sides
square$sides
## when we call the square.to.triangle function the 'square' object
## gets modified, eventhough we don't pass it as argument. That is because
## it is referenced inside the function
square.to.triangle(2)

square$sides

## but if we do
square <- Polygon$new(sides = 4)

square.to.triangle <- function(a){    
    triangle <- square$copy()
    triangle$sides <- 3
    return(a+2)
}

square$sides
square.to.triangle(2)
## the object remains unchanged
square$sides


## -----------------------------------------------------------------------------

library(sitree)
res <- sitree (tree.df   = tr,
                 stand.df  = fl,
                 functions = list(
                     fn.growth     = 'grow.dbhinc.hgtinc',
                     fn.mort       = 'mort.B2007',
                     fn.recr       = 'recr.BBG2008',
                     fn.management = 'management.prob',
                     fn.tree.removal = 'mng.tree.removal',
                     fn.modif      = NULL, 
                     fn.prep.common.vars = 'prep.common.vars.fun'
                 ),
                 n.periods = 5,
                 period.length = 5,
                 mng.options = NA,
                 print.comments = FALSE,
                 fn.dbh.inc = "dbhi.BN2009",
                 fn.hgt.inc =  "height.korf", 
                 fun.final.felling = "harv.prob",
                 fun.thinning      = "thin.prob",
                 per.vol.harv = 0.83
                 )
 

 ## getTrees(i, j)  -- obtains the information of the i trees, on the j periods,
 ## by default it selects all. It does not display it, it passes the value.
 ## It returns a list with elements plot.id, treeid, dbh.mm, height.dm, yrs.sim,
 ## tree.sp
 
 get.some.trees <- res$live$getTrees(1:3, 2:5)

 ## extractTrees(i)  -- extracts the i trees, it removed the trees from the
 ## original object and it passes the information. It returns a list.

 dead <- res$live$extractTrees(4:7)

 ## addTrees(x) -- x should be a list
 
 res$live$addTrees(dead)

 ## last.time.alive. It checks when was the last DBH measured.
 new.dead.trees <- trListDead$new(
      data = dead,
      last.measurement = cbind(
        do.call("dead.trees.growth"
              , args = list(
                  dt     = dead,
                  growth = data.frame(dbh.inc.mm     = rep(3, 4),
                                      hgt.inc.dm  = rep(8, 4)),
                  mort   = rep(TRUE, 4),
                  this.period = "t2")
                ),
        found.dead = "t3"
      ),
      nperiods = res$live$nperiods
      )
 
 lta <- new.dead.trees$last.time.alive()
 
 ## which in this case differs from the data stored under the last.measurement
 ## field because we have defined it artificially above as "t3"
 lta
 new.dead.trees$last.measurement$found.dead
 ## But we can remove the data from the periods after it was found dead
 new.dead.trees$remove.next.period("t3")
 new.dead.trees$remove.next.period("t4")
 new.dead.trees$remove.next.period("t5")
 ## and now results do match
 lta <- new.dead.trees$last.time.alive()
 ## last time it was alive was in "t2"
 lta
 ## ant it was found dead in "t3"
 new.dead.trees$last.measurement$found.dead
 


  
  

## -----------------------------------------------------------------------------
 
set.seed(2017)

n.periods <- 50
res <- sitree (tree.df   = tr,
                stand.df  = fl,
                functions = list(
                    fn.growth     = 'grow.dbhinc.hgtinc',
                    fn.mort       = 'mort.B2007',
                    fn.recr       = 'recr.BBG2008',
                    fn.management = 'management.prob',
                    fn.tree.removal = 'mng.tree.removal',
                    fn.modif      = NULL,
                    fn.prep.common.vars = 'prep.common.vars.fun'
                ),
                n.periods = n.periods,
                period.length = 5,
                mng.options = NA,
                print.comments = FALSE,
                fn.dbh.inc = "dbhi.BN2009",
                fn.hgt.inc =  "height.korf", 
                fun.final.felling = "harv.prob",
                fun.thinning      = "thin.prob",
                per.vol.harv = 0.83
                )





## -----------------------------------------------------------------------------

dbh.mm <- res$live$data$dbh.mm
dbh.mm.short <- reshape(dbh.mm, 
                        varying = paste0("t", 0:n.periods), 
                        timevar = "period",
                        direction = "long", sep = "")
head(dbh.mm.short)
dbh.mm.short$t[dbh.mm.short$t == 0] <- NA
library(ggplot2)
ggplot(dbh.mm.short, aes(x = t)) + geom_histogram() + ylab('dbh.mm') +
   facet_wrap(~ period) + theme_minimal()

## -----------------------------------------------------------------------------
vol <- data.frame(matrix(NA, ncol = n.periods+1, nrow = length(res$plot.data$plot.id)))
names(vol) <- paste0("t", 0:n.periods)
for (i.period in 0:n.periods){
    sa <- prep.common.vars.fun (
        tr = res$live, fl= res$plot.data,
        i.period, this.period = paste0("t", i.period),
        common.vars = NULL, 
        period.length = 5 )
    
    vol[, (i.period +1)] <- sa$res$vuprha.m3.ha 
    ## This is volume per ha, if we prefer just m3 we multiply by ha2total
    ## ha2total is the number of ha represented by the plot
    vol[, (i.period +1)] <- vol[, (i.period +1)] * sa$fl$ha2total
}
vol.m3.short <- reshape(vol, 
                        varying = paste0("t", 0:n.periods),
                        timevar = "period",
                        direction = "long",
                    sep = "")
vol.m3.short$t[vol.m3.short$t == 0] <- NA
total.standing.volume <- aggregate(t ~ period, data = vol.m3.short, FUN = sum)
total.standing.volume$vol.mill.m3  <- total.standing.volume$t/1e6

ggplot(total.standing.volume,
       aes(period, vol.mill.m3))   + geom_line()+
  ylab("standing volume (mill m3)") + theme_minimal()




## -----------------------------------------------------------------------------
vol <- data.frame(matrix(NA, ncol = n.periods + 1,
                         nrow = length(res$plot.data$plot.id)))
## res$removed$data only contains the "history of the tree", but we need
## the dbh and height of the tree at harvest time
names(vol) <- paste0("t", 0:n.periods)
removed <- recover.last.measurement(res$removed)

for (i.period in 0:n.periods){
    harv.vol <- prep.common.vars.fun (
        tr = res$removed,
        fl = res$plot.data,
        i.period,
        this.period = paste0("t", i.period),
        common.vars = NULL,
        period.length = 5 )
    
    vol[, (i.period +1)] <- harv.vol$res$vuprha.m3.ha 
    ## This is volume per ha, if we prefer just m3.
    vol[, (i.period +1)] <- vol[, (i.period +1)] * sa$fl$ha2total
}
names(vol) <- paste0(substr(names(vol), 1, 1), ".", substr(names(vol), 2, 3))

vol.m3.short <- reshape(vol, 
                        varying = paste0("t.", 0:n.periods),
                        timevar = "period",
                        idvar = "id",
                        direction = "long"
                        )
vol.m3.short$t[vol.m3.short$t == 0] <- NA
harv.total <- aggregate(t ~ period, data = vol.m3.short, FUN = sum)

ggplot(harv.total, aes(period, t))   + geom_line()+
  ylab("harvested volume ( m3)") + theme_minimal()




## -----------------------------------------------------------------------------
vol <- data.frame(matrix(NA, ncol = n.periods + 1,
                         nrow = length(res$plot.data$plot.id)))
names(vol) <- paste0("t", 0:n.periods)
dead <- recover.last.measurement(res$dead)

for (i.period in 0:n.periods){
  vol[, (i.period +1)] <-
    prep.common.vars.fun (
      tr = dead,
      fl= res$plot.data,
      i.period,
      this.period = paste0("t", i.period),
      common.vars = NULL,
      period.length = 5 )$res$vuprha.m3.ha 
    
    ## This is volume per ha, if we prefer just m3.
    vol[, (i.period +1)] <- vol[, (i.period +1)] * sa$fl$ha2total
}

names(vol) <- paste0(substr(names(vol), 1, 1), ".", substr(names(vol), 2, 3))
vol.m3.short <- reshape(vol, 
                        varying = paste0("t.", 0:n.periods),
                        timevar = "period",
                        idvar = "id",
                        direction = "long"
                        )

head(vol.m3.short)

## let's plot dead trees by plot, for the first 10 plots
## to look at the variation
ggplot(vol.m3.short[vol.m3.short$id %in% 1:10,],
       aes(period, t, group = id, col = as.factor(id)))   +
  geom_line()+
  ylab("Dead trees volume (mill m3)") + theme_minimal()



## -----------------------------------------------------------------------------
age <- res$plot.data$stand.age.years
age.short<- reshape(age, 
                    varying = paste0("t", 0:(n.periods-1)), 
                    timevar = "period",
                    idvar = "id",                    
                    direction = "long",
                    sep = ""
                    )
head(age.short)
ggplot(age.short, aes(x = t)) + geom_histogram() + ylab('dbh.mm') +
   facet_wrap(~ period) + theme_minimal()

## -----------------------------------------------------------------------------
ET2001 <- function (tr, fl, common.vars, this.period, ...) {
    dbh.mm <- tr$data[["dbh.mm"]][, this.period]
    p.functions <-
        data.frame(a0 = c( 8.06,   8.49, 4.89,  5.16),
                   b1 = c(-6.7, -14.27, -2.528, -7.35),
                   b2 = c(-0.03,  -0.05, 0,     -0.02),
                   b3 = c(-0.03, -0.08, 0,     0 ),
                   b4 = c(-0.01, -0.08, 0,     0 )
                   )
    rownames(p.functions) <- c("spruce", "pine", "birch", "other")
  
    logit <- p.functions[common.vars$spp, "a0"] +
        p.functions[common.vars$spp, "b1"] * (dbh.mm/10)^(-1) +
        p.functions[common.vars$spp, "b2"] * common.vars$PBAL.m2.ha +
        p.functions[common.vars$spp, "b3"] * fl$SI.m[common.vars$i.stand] + 
        p.functions[common.vars$spp, "b4"] * common.vars$pr.spp.ba$spru
    mort.B <- 1- (1/(1 + exp(-logit)))
    mort <- ifelse(mort.B >= runif(nrow(tr$data$dbh.mm),  0, 1), TRUE, FALSE)
    return(mort)
}


## -----------------------------------------------------------------------------
SBA.m2.ha <- list()
set.seed(2017)
for ( i.to in 1:20){
 
  result.sitree.ET2001 <-
    sitree (tree.df   = tr,
            stand.df  = fl,
            functions = list(
              fn.growth     = 'grow.dbhinc.hgtinc',
              fn.mort       = 'ET2001',
              fn.recr       = 'recr.BBG2008',
              fn.management = NULL,
              fn.tree.removal = NULL,
              fn.modif      = NULL, 
              fn.prep.common.vars = 'prep.common.vars.fun'
            ),
            n.periods = 16,
            period.length = 5,
            mng.options = NA,
            print.comments = FALSE,
            fn.dbh.inc    = 'dbhi.BN2009',
            fn.hgt.inc    = 'height.korf'
            )
    
  ## We extract basal area from sitree.summary
  SBA.m2.ha[[i.to]] <-
    attr(sitree.summary(
      result.sitree.ET2001,
      plots = c(1),
      by.stand = TRUE,
      plot.all.together = TRUE,
      plot = FALSE), "data")$SBA.m2.ha
}

library(data.table)
SBA.m2.ha.ET2001 <- rbindlist(SBA.m2.ha)
SBA.m2.ET2001 <- aggregate(t ~ period + plot.id, data = SBA.m2.ha.ET2001,
                              FUN = mean)                              

## -----------------------------------------------------------------------------

SBA.m2.ha <- list()
set.seed(2017)
for ( i.to in 1:20){
  
  result.sitree <-
    sitree (tree.df   = tr,
            stand.df  = fl,
            functions = list(
              fn.growth     = 'grow.dbhinc.hgtinc',
              fn.mort       = 'mort.B2007',
              fn.recr       = 'recr.BBG2008',
              fn.management = NULL,
              fn.tree.removal = NULL,
              fn.modif      = NULL, 
              fn.prep.common.vars = 'prep.common.vars.fun'
            ),
            n.periods = 16,
            period.length = 5,
            mng.options = NA,
            print.comments = FALSE,
            fn.dbh.inc    = 'dbhi.BN2009',
            fn.hgt.inc    = 'height.korf'
            )
  ## Basal area
  SBA.m2.ha[[i.to]] <- attr(sitree.summary(
    result.sitree,
    plots = c(1),
    by.stand = TRUE,
    plot.all.together = TRUE,
    plot = FALSE), "data")$SBA.m2.ha
  
}

SBA.m2.ha.B2007 <- rbindlist(SBA.m2.ha)
SBA.m2.B2007 <- aggregate(t ~ period + plot.id, data = SBA.m2.ha.B2007,
                              FUN = mean)

SBA.m2.B2007$mort <- "mort.B2007"
SBA.m2.ET2001$mort <- "ET2001"



## -----------------------------------------------------------------------------
mort.data <- rbind(SBA.m2.B2007, SBA.m2.ET2001)
mort.data$uid  <- as.factor(paste0(mort.data$plot.id, mort.data$mort))
ggplot(mort.data[mort.data$plot.id %in% 1:10,],
       aes(  period, t, col = mort, group = uid)) +
  geom_line() + ylab ( "Stand basal area (m2)")+ 
  theme(legend.title = element_blank())


