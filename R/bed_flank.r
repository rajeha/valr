#' Create flanks from input intervals.
#' 
#' @param x tbl of intervals
#' @param genome tbl of chrom sizes
#' @param both number of bases on both sizes 
#' @param left number of bases on left side
#' @param right number of bases on right side
#' @param strand define \code{left} and \code{right} based on strand
#' @param fraction define flanks based on fraction of interval length
#' @param trim adjust coordinates for out-of-bounds intervals
#' 
#' @return \code{data_frame}
#' 
#' @seealso
#'   \url{http://bedtools.readthedocs.org/en/latest/content/tools/flank.html}
#' 
#' @examples 
#' genome <- tibble::frame_data(
#'  ~chrom, ~size,
#'  "chr1", 5000
#' )
#' 
#' x <- tibble::frame_data(
#'  ~chrom, ~start, ~end, ~name, ~score, ~strand,
#'  "chr1", 500,    1000, '.',   '.',    '+',
#'  "chr1", 1000,   1500, '.',   '.',    '-'
#' )
#' 
#' bed_flank(x, genome, left = 100)
#' bed_flank(x, genome, right = 100)
#' bed_flank(x, genome, both = 100)
#'
#' bed_flank(x, genome, both = 0.5, fraction=TRUE)
#' 
#' @export
bed_flank <- function(x, genome, both = 0, left = 0,
                      right = 0, fraction = FALSE,
                      strand = FALSE, trim = FALSE) {

  assert_that(both > 0 || left > 0 || right > 0)
  
  if (strand) {
    assert_that( 'strand' %in% colnames(x) )
  }
  
  if (both != 0 && (left != 0 || right != 0)) {
    stop('ambiguous side spec for bed_flank')
  } 
  
  if (both) {
    left <- both 
    right <- both
  }
  
  if (strand) {
    if (fraction) {
      res <- mutate(x, .interval_size = end - start,
               left_start = ifelse(strand == '+', 
                                start - round( left * .interval_size ),
                                end),
               left_end = ifelse(strand == '+',
                              start,
                              end + round( left * .interval_size )),
               right_start = ifelse(strand == '+',
                                end,
                                start - round( right * .interval_size )),
               right_end = ifelse(strand == '+',
                              end + round( right * .interval_size ),
                              start))
      
     res <- select(res, -start, -end, -.interval_size) 
      
    } else {
      res <- mutate(x, left_start = ifelse(strand == '+', 
                                start - left,
                                end),
               left_end = ifelse(strand == '+',
                              start,
                              end + left),
               right_start = ifelse(strand == '+',
                                end,
                                start - right),
               right_end = ifelse(strand == '+',
                              end + right,
                              start))
      res <- select(res, -start, -end)
    }
    
  } else {
    if (fraction) {
      res <- mutate(x, .interval_size = end - start,
               left_start =  start - round( left * .interval_size ), 
               left_end = start, 
               right_start = end, 
               right_end = end + round( right * .interval_size ))
      res <- select(res, -start, -end, -.interval_size) 
      
    } else {
      res <- mutate(x, left_start = start - left, 
               left_end = start, 
               right_start = end, 
               right_end = end + right)
      res <- select(res, -start, -end)
    }
  }
  
  if (right && !left) {
    res <- mutate(res, start = right_start,
             end = right_end)
    res <- select(res, chrom, start, end, everything(), 
             -left_start, -left_end, -right_start, -right_end)

  } else if (left && !right) {
    res <- mutate(res, start = left_start,
             end = left_end)
    res <- select(res, chrom, start, end, everything(), 
             -left_start, -left_end, -right_start, -right_end)

  } else {
    res <- gather(res, key, value, left_start, left_end, right_start, right_end)
    res <- separate(res, key, c('pos', 'key'), sep = '_')
    res <- spread(key, value)
    res <- select(res, chrom, start, end, everything(), -pos) 
  }   

  res <- bound_intervals(res, genome, trim)
  res <- bed_sort(res)
  
  res
}
 
