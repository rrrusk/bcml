#!/bin/bash
cp log.txt ordlog.txt
$1 > log.txt
colordiff -u model.txt log.txt
