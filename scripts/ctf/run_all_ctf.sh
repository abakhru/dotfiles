#!/bin/bash

# cd to whereever you have ctf dir
cd ~/source/server-ready/python/ctf

for i in notifications esa
do
  cd $i
  for j in `\ls test/*.py`
  do
    \nosetests -e "^Setup" --attr=\!disabled -svm 'test' $j
  done
  cd -
done
