#! /usr/bin/env bash

pkill -f child-projects
rm -rf ./tmp/child-projects/*

testSuites=('testsuite-part1' 'testsuite-part2' 'testsuite-part3')
for testSuiteName in ${testSuites[@]}; do
    rsync -av --exclude 'tmp/child-projects/*' --exclude 'tmp/test/*' --exclude 'tmp/testsuite/*' . "./tmp/child-projects/${testSuiteName}" >/dev/null
    logFile="./tmp/child-projects/${testSuiteName}.log"
    touch "${logFile}"
    time "./tmp/child-projects/${testSuiteName}/${testSuiteName}.sh" > "${logFile}" &
done

wait

for testSuiteName in ${testSuites[@]}; do
    cat "./tmp/child-projects/${testSuiteName}.log"
done

echo "Parallel Run Complete"
