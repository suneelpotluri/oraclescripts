alter session set nls_date_format = 'yyyy-mm-dd hh24:mi:ss';
set pagesize 9999
select vertime, csno, fno, bno, bct from x$krcbit
where vertime >= (select curr_vertime from x$krcfde
                  where csno=x$krcbit.csno and fno=x$krcbit.fno)
order by fno, bno;

