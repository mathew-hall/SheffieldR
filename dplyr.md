## Basics:

plyr and dplyr don't "add" behaviour to data frames, so we still use them (mostly):


```r
myDT <- data.frame(
    number=1:3,
    letter=c('a','b','c')
  ) # like data.frame constructor
myDT
```

```
##   number letter
## 1      1      a
## 2      2      b
## 3      3      c
```

We still rely on basics for reading data from CSVs and the like. Dplyr provides a `tbl_df` class, which, like data table, won't spam your terminal.


```r
library(dplyr)
```

```
## 
## Attaching package: 'dplyr'
## 
## The following object is masked from 'package:stats':
## 
##     filter
## 
## The following objects are masked from 'package:base':
## 
##     intersect, setdiff, setequal, union
```

```r
D <- read.csv("TB_Burden_Data.csv")
D <- tbl_df(D)
```

## Pipes:

Dplyr's interface relies heavily on constructing "pipelines" of operations. Unlike plyr and data.table, these are *separate* function calls.



```r
D %>% 
	filter(country == 'Afghanistan') %>% 
	summarise(mean(e_prev_100k))
```

```
## Source: local data frame [1 x 1]
## 
##   mean(e_prev_100k)
## 1            376.42
```

Selecting columns:

```r
D %>% select(e_prev_100k,e_prev_100k_lo,e_prev_100k_hi)
```

```
## Source: local data frame [5,120 x 3]
## 
##    e_prev_100k e_prev_100k_lo e_prev_100k_hi
## 1          306            156            506
## 2          343            178            562
## 3          371            189            614
## 4          392            194            657
## 5          410            198            697
## 6          424            199            733
## 7          438            202            764
## 8          448            203            788
## 9          454            204            800
## 10         446            203            782
## ..         ...            ...            ...
```

Summarisation with multiple columns:


```r
D %>% 
	filter(country == 'Afghanistan') %>% 
	summarise(
		mid=mean(e_prev_100k),
       		lo=mean(e_prev_100k_lo),
       	 	hi=mean(e_prev_100k_hi)
	)
```

```
## Source: local data frame [1 x 3]
## 
##      mid     lo     hi
## 1 376.42 187.21 630.67
```



```r
D %>%
	group_by(country) %>%
	summarise(mid=mean(e_prev_100k))
```

```
## Source: local data frame [219 x 2]
## 
##                country     mid
## 1          Afghanistan 376.417
## 2              Albania  29.333
## 3              Algeria 124.375
## 4       American Samoa  14.567
## 5              Andorra  29.921
## 6               Angola 388.583
## 7             Anguilla  52.417
## 8  Antigua and Barbuda   8.725
## 9            Argentina  55.500
## 10             Armenia  76.875
## ..                 ...     ...
```

Pete's more complicated example:


```r
D %>% 
	group_by(country, year > 2000) %>%
	summarise( 
		lo=mean(e_prev_100k_lo),
       		hi=mean(e_prev_100k_hi))
```

```
## Source: local data frame [431 x 4]
## Groups: country
## 
##           country year > 2000       lo      hi
## 1     Afghanistan       FALSE 193.4545 695.000
## 2     Afghanistan        TRUE 181.9231 576.231
## 3         Albania       FALSE  15.1818  60.273
## 4         Albania        TRUE  11.1077  45.385
## 5         Algeria       FALSE  57.0000 184.364
## 6         Algeria        TRUE  69.2308 223.154
## 7  American Samoa       FALSE   8.3182  34.727
## 8  American Samoa        TRUE   4.4077  19.923
## 9         Andorra       FALSE  19.0636  83.545
## 10        Andorra        TRUE   6.9538  30.538
## ..            ...         ...      ...     ...
```

Sorting is straight forward. The pipe isn't specific to dplyr functions, so you can use it to stuff results into functions.


```r
D %>% 
	arrange(e_prev_100k) %>% 
	mutate(id=row_number()) %>%
	select(id, e_prev_100k) %>% plot
```

![plot of chunk unnamed-chunk-8](figure/unnamed-chunk-8-1.png) 

Pipes aren't magic, they simply flip the argument and the function around.

```r
plot(D %>% 
	arrange(e_prev_100k) %>% 
	mutate(id=row_number()) %>%
	select(id, e_prev_100k))
```

![plot of chunk unnamed-chunk-9](figure/unnamed-chunk-9-1.png) 

Adding new columns uses mutate:

```r
D %>% mutate(country_t = paste0(country,year)) %>% select(country_t)
```

```
## Source: local data frame [5,120 x 1]
## 
##          country_t
## 1  Afghanistan1990
## 2  Afghanistan1991
## 3  Afghanistan1992
## 4  Afghanistan1993
## 5  Afghanistan1994
## 6  Afghanistan1995
## 7  Afghanistan1996
## 8  Afghanistan1997
## 9  Afghanistan1998
## 10 Afghanistan1999
## ..             ...
```

## Databases

Up to now, most of the advantages arise from using pipes and primitives that exist in base R or plyr. The real advantage of dplyr arises when you need to use a database.

For example, suppose we have a big data frame:


```r
data <- tbl_df(data.frame(x=1:200, y=runif(4), z=runif(50)))
# You need to set this env var to make the huge data set.
if(Sys.getenv("USE_LOADS_OF_MEMORY") == "yes"){
	data <- data.frame(x=1:200000000, y=runif(4), z=runif(50))
	format(object.size(data), units="GB")
}

db <- src_sqlite("data.sqlite", create=T)
```

```
## Loading required package: RSQLite
## Loading required package: methods
## Loading required package: DBI
## Loading required package: RSQLite.extfuns
```

```r
copy_to(db, data, temporary=F)
```

```
## Error: Table data already exists.
```

Aggregations over large data frames often get wedged when memory runs out. dplyr makes it easy to shift computation to a database without changing anything (most of the time).

Loading data is straightforward. dplyr works with a bunch of databases out of the box, including SQLite (a simple, server-free database). Loading data is straight forward:


```r
src <- src_sqlite("data.sqlite")
data <- tbl(src, "data")
data
```

```
## Source: sqlite 3.7.17 [data.sqlite]
## From: data [200 x 3]
## 
##     x       y        z
## 1   1 0.21825 0.462862
## 2   2 0.49525 0.142464
## 3   3 0.58003 0.711791
## 4   4 0.97274 0.086648
## 5   5 0.21825 0.936606
## 6   6 0.49525 0.843326
## 7   7 0.58003 0.397523
## 8   8 0.97274 0.462304
## 9   9 0.21825 0.050347
## 10 10 0.49525 0.400197
## .. ..     ...      ...
```
We can perform computation on the data as if it were a local data frame. dplyr will try to map functions to SQL commands, which is far faster. Using a database means larger-than-memory datasets can be used without much more effort.


```r
data %>% summarise(mean(x), max(y), mean(z))
```

```
##   mean(x)  max(y) mean(z)
## 1   100.5 0.70262 0.54515
```

When SQL is used, dplyr won't evaluate operations as they're given. It builds up the full pipeline then renders it to SQL when it's needed.


```r
	unevaluated <- data %>% summarise(mean(x), max(y), mean(z))
```

This appears to run quickly, because all dplyr's doing is remembering the query. If computation doesn't need to go into R, like this example, `dplyr` can automatically create a temporary table with the results using the `compute` command:


```r
	unevaluated %>% compute()
```

```
##   mean(x)  max(y) mean(z)
## 1   100.5 0.70262 0.54515
```

### Gotchas

When using SQL data frames, built-in R commands aren't available. If dplyr can't map an expression to SQL, you'll get a weird error. You can see what dplyr is sending by using `translate_sql`:


```r
translate_sql(exp(-x - 5))
```

```
## <SQL> EXP( - "x" - 5.0)
```
In cases where the database can't do what you need, you'll often have to get the data back into R to process it. You manually do this by using `collect` on your data:


```r
	D %>% collect()
```

```
## Source: local data frame [5,120 x 47]
## 
##        country iso2 iso3 iso_numeric g_whoregion year e_pop_num
## 1  Afghanistan   AF  AFG           4         EMR 1990  11731193
## 2  Afghanistan   AF  AFG           4         EMR 1991  12612043
## 3  Afghanistan   AF  AFG           4         EMR 1992  13811876
## 4  Afghanistan   AF  AFG           4         EMR 1993  15175325
## 5  Afghanistan   AF  AFG           4         EMR 1994  16485018
## 6  Afghanistan   AF  AFG           4         EMR 1995  17586073
## 7  Afghanistan   AF  AFG           4         EMR 1996  18415307
## 8  Afghanistan   AF  AFG           4         EMR 1997  19021226
## 9  Afghanistan   AF  AFG           4         EMR 1998  19496836
## 10 Afghanistan   AF  AFG           4         EMR 1999  19987071
## ..         ...  ...  ...         ...         ...  ...       ...
## Variables not shown: e_prev_100k (dbl), e_prev_100k_lo (dbl),
##   e_prev_100k_hi (dbl), e_prev_num (dbl), e_prev_num_lo (dbl),
##   e_prev_num_hi (dbl), source_prev (fctr), e_mort_exc_tbhiv_100k (dbl),
##   e_mort_exc_tbhiv_100k_lo (dbl), e_mort_exc_tbhiv_100k_hi (dbl),
##   e_mort_exc_tbhiv_num (dbl), e_mort_exc_tbhiv_num_lo (dbl),
##   e_mort_exc_tbhiv_num_hi (dbl), e_mort_tbhiv_100k (dbl),
##   e_mort_tbhiv_100k_lo (dbl), e_mort_tbhiv_100k_hi (dbl), e_mort_tbhiv_num
##   (dbl), e_mort_tbhiv_num_lo (dbl), e_mort_tbhiv_num_hi (dbl), source_mort
##   (fctr), e_inc_100k (dbl), e_inc_100k_lo (dbl), e_inc_100k_hi (dbl),
##   e_inc_num (dbl), e_inc_num_lo (dbl), e_inc_num_hi (dbl), source_inc
##   (fctr), e_tbhiv_prct (dbl), e_tbhiv_prct_lo (dbl), e_tbhiv_prct_hi
##   (dbl), e_inc_tbhiv_100k (dbl), e_inc_tbhiv_100k_lo (dbl),
##   e_inc_tbhiv_100k_hi (dbl), e_inc_tbhiv_num (dbl), e_inc_tbhiv_num_lo
##   (dbl), e_inc_tbhiv_num_hi (dbl), source_tbhiv (lgl), c_cdr (dbl),
##   c_cdr_lo (dbl), c_cdr_hi (dbl)
```

This brings the whole table in as a data frame. From there you can use the full suite of R functions on it.

The `copy_to` function makes it straight-forward to put data back into the database. If you do have to pull stuff into R to process it, you can use `copy_to` to immediately push it back, and operate on the stored table instead.

Unlike plyr, dplyr provides a much higher level of abstraction, which means some things that are easy in plyr don't quite fit into its workflow.  For example, there's no (easy) way of applying a function to rows in a data frame that returns more than one value, or doesn't return anything (for example, plotting).
