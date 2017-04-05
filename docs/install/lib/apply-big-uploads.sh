#!/bin/bash

set -x
perl -i -pe 's/int zend_atoi/long zend_atoi/' Zend/zend_operators.[ch];
perl -i -pe 's/\n/@@@@@@/g' Zend/zend_operators.c;
perl -i -pe 's/(long zend_atoi.*?)int retval/$1long retval/m' Zend/zend_operators.c;
perl -i -pe 's/@@@@@@/\n/g' Zend/zend_operators.c;
perl -i -pe 's/atoi\(content_length\)/atol(content_length)/' `find sapi -name '*.c'`;
perl -i -pe 's/\(uint\)( SG\(request_info\))/$1/' `find sapi -name '*.c'`;
perl -i -pe 's/uint post_data_length, raw/uint IGNORE_post_data_length, IGNORE_raw/' main/SAPI.h;
perl -i -pe 's/} sapi_request_info/\tlong post_data_length, raw_post_data_length;\n} sapi_request_info/' main/SAPI.h;
perl -i -pe 's/int read_post_bytes/long read_post_bytes/'    main/SAPI.h;
perl -i -pe 's/int boundary_len *= *0, *total_bytes *= *0/long total_bytes=0; int boundary_len=0/' main/rfc1867.c;
perl -i -pe 's/int max_file_size *= *0,/long max_file_size = 0; int /' main/rfc1867.c;
exit 0;
