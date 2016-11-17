#! /usr/bin/env bash

tests_dir=$(cd "$(dirname "$0")"; pwd)
test_config_dir="${tests_dir}/_files"
vagrant_dir="${tests_dir}/tmp/test/magento2-vagrant"
current_log_file_path="${tests_dir}/tmp/test/current-test.log"
magento_codebase_stash_dir="${tests_dir}/tmp/testsuite/codebases"
logs_dir="${tests_dir}/logs"
reports_dir="${tests_dir}/reports"
current_config_name=""
current_codebase=""
current_magento_base_url=""

SHUNIT_OUTPUTDIR="${reports_dir}"

# Colors for CLI output
bold=$(printf "\e[1m")
green=$(printf "\e[32m")
blue=$(printf "\e[34m")
red=$(printf "\e[31m")
grey=$(printf "\e[37m")
regular=$(printf "\e[m")
