#!/bin/bash
cp log.txt ordlog.txt
$1 > log.txt
colordiff -u ordlog.txt log.txt
