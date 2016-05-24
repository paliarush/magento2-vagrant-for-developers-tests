#! /usr/bin/env bash

## Global variables declaration

tests_dir=$(cd "$(dirname "$0")"; pwd)
test_config_dir="${tests_dir}/_files"
vagrant_dir="${tests_dir}/tmp/test/magento2-vagrant"
current_log_file_path="${tests_dir}/tmp/test/current-test.log"
magento_codebase_stash_dir="${tests_dir}/tmp/testsuite/codebases"
logs_dir="${tests_dir}/logs"
current_config_name=""
current_codebase=""
current_magento_base_url=""

## Setup and tear down

function oneTimeSetUp
{
    clearLogs
}

function setUp()
{
    echo "===TEST START==="
    stashMagentoCodebase
    clearTestTmp
}

function tearDown()
{
    stashLogs
    stashMagentoCodebase
    clearTestTmp
    echo "====TEST END====
    "
}

function oneTimeTearDown()
{
    echo "
See logs in ${logs_dir}"
}

## Tests

function testNoCustomConfig()
{
    current_config_name="no_custom_config"
    current_codebase="ce"
    installEnvironment
    executeCommonAssertions
}

function testCePreferSource()
{
    current_config_name="ce_prefer_source"
    current_codebase="ce"
    installEnvironment
    executeCommonAssertions
}

function testCePhp5()
{
    current_config_name="ce_php5"
    current_codebase="ce"
    installEnvironment
    executeCommonAssertions
}

function testEe()
{
    current_config_name="ee"
    current_codebase="ee"
    installEnvironment
    executeCommonAssertions
    executeEeNfsAssertions
}

function testEeNoNfs()
{
    current_config_name="ee_no_nfs"
    current_codebase="ee"
    installEnvironment
    executeCommonAssertions
}

## Helper methods

function installEnvironment()
{
    downloadVagrantProject
    unstashMagentoCodebase
    configureVagrantProject
    deployVagrantProject
}

function executeCommonAssertions()
{
    # Make sure Magento was installed and is accessible
    assertMagentoInstalledSuccessfully
    assertMagentoAccessible
    assertMagentoCliWorks

    # Make sure Magento is still accessible after restarting services
    assertMysqlRestartWorks
    assertApacheRestartWorks
    assertMagentoAccessible

    # Make sure Magento reinstall script works
    assertMagentoReinstallWorks
    assertMagentoAccessible
}

function executeEeNfsAssertions()
{
    assertMagentoSwitchToEeWorks
    assertMagentoAccessible
    assertMagentoSwitchToCeWorks
    assertMagentoAccessible
}

function downloadVagrantProject()
{
    echo "## downloadVagrantProject"
    echo "## downloadVagrantProject" >>${current_log_file_path}
    cd ${tests_dir}
    git clone git@github.com:paliarush/magento2-vagrant-for-developers.git ${vagrant_dir} >>${current_log_file_path} 2>&1
}

function configureVagrantProject()
{
    echo "## configureVagrantProject"
    echo "## configureVagrantProject" >>${current_log_file_path}
    current_config_path="${test_config_dir}/${current_config_name}_config.yaml"
    if [ -f ${current_config_path} ]; then
        cp ${current_config_path} "${vagrant_dir}/etc/config.yaml"
    fi
}

function deployVagrantProject()
{
    echo "## deployVagrantProject"
    echo "## deployVagrantProject" >>${current_log_file_path}
    cd ${vagrant_dir}
    bash init_project.sh >>${current_log_file_path} 2>&1
}

function stashMagentoCodebase()
{
    echo "## stashMagentoCodebase"
    echo "## stashMagentoCodebase" >>${current_log_file_path}
    if [ -d ${vagrant_dir}/magento2ce ]; then
        magento_stash_dir="${magento_codebase_stash_dir}/${current_codebase}"
        rm -rf ${magento_stash_dir}
        mkdir -p ${magento_stash_dir}
        mv ${vagrant_dir}/magento2ce ${magento_stash_dir}/magento2ce
        rm -rf ${magento_stash_dir}/magento2ce/var/*
        rm -rf ${magento_stash_dir}/magento2ce/vendor/*
        rm -rf ${magento_stash_dir}/magento2ce/pub/static/*
        rm -rf ${magento_stash_dir}/magento2ce/app/etc/config.php
    fi
}

function unstashMagentoCodebase()
{
    echo "## unstashMagentoCodebase"
    echo "## unstashMagentoCodebase" >>${current_log_file_path}
    magento_stash_dir="${magento_codebase_stash_dir}/${current_codebase}/magento2ce"
    if [ -d ${magento_stash_dir} ]; then
        mv ${magento_stash_dir} ${vagrant_dir}/magento2ce
    fi
}

function stashLogs()
{
    log_file_path="${logs_dir}/${current_config_name}.log"
    cp ${current_log_file_path} ${logs_dir}/${current_config_name}.log
}

function clearLogs()
{
    rm -f ${logs_dir}/*
}

function clearTestTmp()
{
    echo "## clearTestTmp"
    echo "## clearTestTmp" >>${current_log_file_path}
    if [ -e ${vagrant_dir} ]; then
        cd ${vagrant_dir}
        vagrant destroy -f &>/dev/null
        cd ${tests_dir}
        rm -rf ${vagrant_dir}
    fi
    rm -f ${current_log_file_path}
}

## Assertions

function assertMagentoInstalledSuccessfully()
{
    echo "## assertMagentoInstalledSuccessfully"
    echo "## assertMagentoInstalledSuccessfully" >>${current_log_file_path}
    cd ${tests_dir}
    output_log="$(cat ${current_log_file_path})"
    pattern="Access storefront at ([a-zA-Z0-9/:\.]+).*"
    if [[ ! ${output_log} =~ ${pattern} ]]; then
        fail "Magento was not installed successfully (Frontend URL is not available in the init script output)"
    fi
    current_magento_base_url=${BASH_REMATCH[1]}
}

function assertMagentoAccessible()
{
    echo "## assertMagentoAccessible"
    echo "## assertMagentoAccessible" >>${current_log_file_path}
    cd ${tests_dir}
    magento_home_page_content="$(curl -sL ${current_magento_base_url})"
    pattern="Magento. All rights reserved."
    assertTrue 'Magento was installed but main page is not accessible.' '[[ ${magento_home_page_content} =~ ${pattern} ]]'
}

function assertMysqlRestartWorks()
{
    echo "## assertMysqlRestartWorks"
    echo "## assertMysqlRestartWorks" >>${current_log_file_path}
    cd ${vagrant_dir}
    cmd_output="$(vagrant ssh -c 'sudo service mysql restart' >>${current_log_file_path} 2>&1)"
    pattern="mysql start/running, process [0-9]+"
    output_log="$(tail -n2 ${current_log_file_path})"
    assertTrue 'MySQL server restart attempt failed' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertApacheRestartWorks()
{
    echo "## assertApacheRestartWorks"
    echo "## assertApacheRestartWorks" >>${current_log_file_path}
    cd ${vagrant_dir}
    cmd_output="$(vagrant ssh -c 'sudo service apache2 restart' >>${current_log_file_path} 2>&1)"
    pattern="\[ OK \]"
    output_log="$(tail -n2 ${current_log_file_path})"
    assertTrue 'Apache restart attempt failed' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertMagentoReinstallWorks()
{
    echo "## assertMagentoReinstallWorks"
    echo "## assertMagentoReinstallWorks" >>${current_log_file_path}
    cd ${vagrant_dir}
    bash m-reinstall >>${current_log_file_path} 2>&1
    pattern="Access storefront at ([a-zA-Z0-9/:\.]+).*"
    output_log="$(tail -n5 ${current_log_file_path})"
    assertTrue 'Magento reinstallation failed (Frontend URL is not available in the output)' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertMagentoSwitchToEeWorks()
{
    echo "## assertMagentoSwitchToEeWorks"
    echo "## assertMagentoSwitchToEeWorks" >>${current_log_file_path}
    cd ${vagrant_dir}
    bash m-switch-to-ee >>${current_log_file_path} 2>&1
    pattern="Access storefront at ([a-zA-Z0-9/:\.]+).*"
    output_log="$(tail -n5 ${current_log_file_path})"
    assertTrue 'Magento switch to EE failed (Frontend URL is not available in the output)' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertMagentoSwitchToCeWorks()
{
    echo "## assertMagentoSwitchToCeWorks"
    echo "## assertMagentoSwitchToCeWorks" >>${current_log_file_path}
    cd ${vagrant_dir}
    bash m-switch-to-ce >>${current_log_file_path} 2>&1
    pattern="Access storefront at ([a-zA-Z0-9/:\.]+).*"
    output_log="$(tail -n5 ${current_log_file_path})"
    assertTrue 'Magento switch to CE failed (Frontend URL is not available in the output)' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertMagentoCliWorks()
{
    echo "## assertMagentoCliWorks"
    echo "## assertMagentoCliWorks" >>${current_log_file_path}
    cd ${vagrant_dir}
    bash m-bin-magento list >>${current_log_file_path} 2>&1
    pattern="theme:uninstall"
    output_log="$(tail -n2 ${current_log_file_path})"
    assertTrue 'Magento CLI does not work.' '[[ ${output_log} =~ ${pattern} ]]'
}

## Call and Run all Tests
. "lib/shunit2-2.1.6/src/shunit2"
