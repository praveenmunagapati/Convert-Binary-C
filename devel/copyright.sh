#!/bin/bash
FROM=2005
TO=2006
for i in `grep -lEIr "Copyright.*$FROM.*Holland" . | grep -v devel | grep -v ppport.h`; do
  echo $i
  wco -l -t '' $i
  perl -i.bak -pe "/Copyright.*Holland/ and s/$FROM/$TO/g" $i
done
