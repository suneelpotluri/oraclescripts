REM
REM Obtained from the text of MetaLink Note #1054939.6 entitled "Compilation
REM of Package is Hanging on Libary Cache Lock and Library Cache Pin"
REM
set echo on feedback on timing on

spool who_is_using

create or replace procedure who_is_using wrapped 
0 
abcd 
abcd 
abcd 
abcd 
abcd 
abcd 
abcd 
abcd 
abcd 
abcd 
abcd 
abcd 
abcd 
abcd 
abcd 
abcd 
7 
200f000 
1 
4               
0 
1e 
c WHO_IS_USING: 
8 OBJ_NAME: 
8 VARCHAR2: 
b DBMS_OUTPUT: 
6 ENABLE: 
7 1000000: 
1 I: 
1 B: 
8 USERNAME: 
3 SID: 
3 SYS: 
7 X$KGLPN: 
1 A: 
9 V$SESSION: 
7 X$KGLOB: 
1 C: 
8 KGLPNUSE: 
1 =: 
5 SADDR: 
5 UPPER:           
8 KGLNAOBJ: 
4 LIKE: 
8 KGLPNHDL: 
8 KGLHDADR: 
4 LOOP: 
8 PUT_LINE: 
1 (: 
2 ||: 
7 TO_CHAR: 
4 ) - : 
0 
 
0 
0 
74 
2 
0 1d 9a 8f a0 b0 3d b4 
55 6a :2 a0 6b 51 a5 57 91 
:2 a0 6b :2 a0 6b ac :2 a0 6b a0 
b9 :2 a0 b9 :2 a0 6b a0 b9 b2 
ee :2 a0 6b a0 7e a0 6b b4 
2e :3 a0 6b a5 b 7e :2 a0 a5 
b b4 2e a 10 :2 a0 6b a0 
7e a0 6b b4 2e a 10 ac 
d0 e5 e9 37 :3 a0 6b 6e 7e 
:3 a0 6b a5 b b4 2e 7e 6e 
b4 2e 7e :2 a0 6b b4 2e a5 
57 b7 a0 47 b7 a4 b1 11 
68 4f 17 b5 
74 
2 
0 3 4 19 15 14 20 13 
25 29 2d 31 35 38 3b 3c 
41 45 49 4d 50 54 58 5b 
5c 60 64 67 11 6b 6f 73 
75 79 7d 80 84 86 87 8e 
92 96 99 9d a0 a4 a7 a8 
ad b1 b5 b9 bc bd bf c2 
c6 ca cb cd ce 1 d3 d8 
dc e0 e3 e7 ea ee f1 f2 
1 f7 fc fd 101 106 10b 10d 
111 115 119 11c 120 123 127 12b 
12f 132 133 135 136 13b 13e 142 
143 148 14b 14f 153 156 157 15c 
15d 162 164 168 16f 171 175 177 
182 186 188 18f 
74 
2 
0 1 b 18 21 :2 18 17 :2 1 
2 :2 e 15 :2 2 6 1c :2 1e 27 
:2 29 1c 11 15 11 1d 11 1f 
29 1f 2b 2f 2b 37 2b c 
11 12 :2 14 1f 1d :2 21 :2 1d 12 
18 :2 1a :3 12 2a 30 :2 2a :5 12 :2 14 
1f 1d :2 21 :2 1d :2 12 :4 c 2 2b 
3 :2 f 18 1b 1d 25 :2 27 :2 1d 
:2 18 2b 2d :2 18 33 35 :2 37 :2 18 
:2 3 2b 6 2 :8 1 
74 
2 
0 :9 1 :6 3 :8 4 :f 5 :9 6 :d 7 :2 6 
:9 8 :2 6 5 :4 4 8 :19 9 8 a 
4 :2 2 :6 1 
191 
2 
:4 0 1 :a 0 70 1 1a 1b 5    
:2 3 :3 0 2 :6 0 5 4 :3 0 7 
:2 0 70 2 8 :2 0 4 :3 0 5 
:3 0 a b 0 6 :2 0 7 c 
e :2 0 6c 7 :3 0 8 :3 0 9 
:3 0 11 12 0 8 :3 0 a :3 0 
14 15 0 9 b :3 0 c :3 0 
18 19 0 d :3 0 e :3 0 8 
:3 0 1d 1e b :3 0 f :3 0 20 
21 0 10 :3 0 22 23 c 25 
49 0 4a :3 0 d :3 0 11 :3 0 
27 28 0 8 :3 0 12 :2 0 13 
:3 0 2a 2c 0 12 2b 2e :3 0 
14 :3 0 10 :3 0 15 :3 0 31 32 
0 10 30 34 16 :2 0 14 :3 0 
2 :3 0 15 37 39 17 36 3b 
:3 0 2f 3d 3c :2 0 d :3 0 17 
:3 0 3f 40 0 10 :3 0 12 :2 0 
18 :3 0 42 44 0 1c 43 46 
:3 0 3e 48 47 :3 0 2 17 26 
0 4b :5 0 4c :2 0 4e 10 4d 
19 :3 0 4 :3 0 1a :3 0 50 51 
0 1b :3 0 1c :2 0 1d :3 0 7  
:3 0 a :3 0 56 57 0 1a 55 
59 1f 54 5b :3 0 1c :2 0 1e 
:3 0 22 5d 5f :3 0 1c :2 0 7 
:3 0 9 :3 0 62 63 0 25 61 
65 :3 0 28 52 67 :2 0 69 2a 
6b 19 :3 0 4e 69 :4 0 6c 2c 
6f :3 0 6f 0 6f 6e 6c 6d 
:6 0 70 0 2 8 6f 72 :2 0 
1 70 73 :6 0 
2f 
2 
:3 0 1 3 1 6 1 d 2 
13 16 3 1c 1f 24 1 33 
2 29 2d 1 38 2 35 3a 
1 58 2 41 45 2 53 5a 
2 5c 5e 2 60 64 1 66 
1 68 2 f 6b 
1 
4 
0 
72 
0     
1 
14 
2 
3 
0 1 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 
0 0 0 0 
2 0 1 
3 1 0 
10 2 0 
0 
/
show errors

spool off

set echo off feedback 6 timing off
