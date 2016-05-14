#! /usr/bin/env bash

## Global variables declaration

test_project_root=$(cd "$(dirname "$0")"; pwd)
vagrant_project_config_dir="${test_project_root}/_files"
vagrant_project_dir="${test_project_root}/tmp/test/magento2-vagrant"
init_project_log_file_path="${test_project_root}/tmp/test/current-test.log"
cached_magento_codebases_path="${test_project_root}/tmp/testsuite/codebases"
logs_dir="${test_project_root}/logs"
current_config_name=""
current_codebase=""

## Setup and tear down

function oneTimeSetUp
{
    clearLogs
}

function setUp()
{
    clearTestTmp
}

function tearDown()
{
    stashLogs
    stashMagentoCodebase
    clearTestTmp
}

function oneTimeTearDown()
{
    echo "
See logs in ${logs_dir}"
}

## Tests

function testNoCustomConfig()
{
    current_config_name="dist"
    current_codebase="ce"
    performStandardTest
}

function testCePreferSource()
{
    current_config_name="ce_prefer_source"
    current_codebase="ce"
    performStandardTest
}

function testCePhp5()
{
    current_config_name="ce_php5"
    current_codebase="ce"
    performStandardTest
}

function testEe()
{
    current_config_name="ee"
    current_codebase="ee"
    performStandardTest
}

function testEeNoNfs()
{
    current_config_name="ee_no_nfs"
    current_codebase="ee"
    performStandardTest
}

## Helper methods

function performStandardTest()
{
    downloadVagrantProject
    unstashMagentoCodebase
    configureVagrantProject
    deployVagrantProject
    assertMagentoInstalled
}

function downloadVagrantProject()
{
    cd ${test_project_root}
    git clone git@github.com:paliarush/magento2-vagrant-for-developers.git ${vagrant_project_dir} >>${init_project_log_file_path} 2>&1
}

function configureVagrantProject()
{
    current_config_path="${vagrant_project_config_dir}/${current_config_name}_config.yaml"
    if [ -f ${current_config_path} ]; then
        cp ${current_config_path} "${vagrant_project_dir}/etc/config.yaml"
    fi
}

function deployVagrantProject()
{
    cd ${vagrant_project_dir}
    bash init_project.sh >>${init_project_log_file_path} 2>&1
}

function stashMagentoCodebase()
{
    if [ -d ${vagrant_project_dir}/magento2ce ]; then
        magento_stash_dir="${cached_magento_codebases_path}/${current_codebase}"
        rm -rf ${magento_stash_dir}
        mkdir -p ${magento_stash_dir}
        mv ${vagrant_project_dir}/magento2ce ${magento_stash_dir}/magento2ce
        rm -rf ${magento_stash_dir}/magento2ce/var/*
        rm -rf ${magento_stash_dir}/magento2ce/vendor/*
        rm -rf ${magento_stash_dir}/magento2ce/pub/static/*
        rm -rf ${magento_stash_dir}/magento2ce/app/etc/config.php
    fi
}

function unstashMagentoCodebase()
{
    magento_stash_dir="${cached_magento_codebases_path}/${current_codebase}/magento2ce"
    if [ -d ${magento_stash_dir} ]; then
        mv ${magento_stash_dir} ${vagrant_project_dir}/magento2ce
    fi
}

function stashLogs()
{
    log_file_path="${logs_dir}/${current_config_name}.log"
    cp ${init_project_log_file_path} ${logs_dir}/${current_config_name}.log
}

function clearLogs()
{
    rm -f ${logs_dir}/*
}

function clearTestTmp()
{
    if [ -e ${vagrant_project_dir} ]; then
        cd ${vagrant_project_dir}
        vagrant destroy -f &>/dev/null
        cd ${test_project_root}
        rm -rf ${vagrant_project_dir}
    fi
    rm -f ${init_project_log_file_path}
}

function assertMagentoInstalled()
{
    cd ${test_project_root}
    output_log="$(cat ${init_project_log_file_path})"
    pattern="Access storefront at ([a-zA-Z0-9/:\.]+).*"
    if [[ ! ${output_log} =~ ${pattern} ]]; then
        fail "Magento was not installed successfully (Frontend URL is not available in the init script output)"
    else
        magento_base_url=${BASH_REMATCH[1]}
        magento_home_page_content="$(curl -sL --max-time 60 --connect-timeout 60 ${magento_base_url})"
        expected_regexp="Magento. All rights reserved."
        assertTrue 'Magento was installed but main page is not accessible.' '[[ ${magento_home_page_content} =~ ${expected_regexp} ]]'
    fi
}

## Call and Run all Tests
. "lib/shunit2-2.1.6/src/shunit2"
