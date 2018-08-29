select file#,
       blocks_changed,
       block_size,
       blocks_changed * block_size bytes_changed,
       round(blocks_changed / blocks * 100, 2) percent_changed
from v$datafile join
     (select fno
             file#,
             sum(bct) blocks_changed
      from (select distinct fno, bno, bct from x$krcbit
            where vertime >= (select curr_vertime from x$krcfde
                              where csno=x$krcbit.csno and fno=x$krcbit.fno))
      group by fno order by 1)
using(file#);
