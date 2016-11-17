#! /usr/bin/env bash

SHUNIT_OUTPUTDIR="./reports"

## Includes

source include/configuration.sh
source include/global_variables.sh
source include/helpers.sh
source include/assertions.sh

## Setup and tear down

function oneTimeSetUp
{
    clearLogs
}

function setUp()
{
    debug_vagrant_project=0
}

function tearDown()
{
    assertNoErrorsInLogs

    if [[ ${delete_test_project_on_tear_down} -eq 1 ]]; then
        stashLogs
        stashMagentoCodebase
        clearTestTmp
    fi

    # TODO: change globally when https://github.com/paliarush/magento2-vagrant-for-developers/issues/58 is unblocked
    vagrant_dir="${tests_dir}/tmp/test/magento2-vagrant"
}

function oneTimeTearDown()
{
    echo "
See logs in ${logs_dir}"
}

## Tests

function testEeNoNfs()
{
    current_config_name="ee_no_nfs"
    current_codebase="ee_2_0"

    # TODO: change globally when https://github.com/paliarush/magento2-vagrant-for-developers/issues/58 is unblocked
    vagrant_dir="${tests_dir}/tmp/test/magento2 vagrant"

    installEnvironment

    assertSourceCodeIsFromBranch "${vagrant_dir}/magento2ce" "2.0"
    assertSourceCodeIsFromBranch "${vagrant_dir}/magento2ce/magento2ee" "2.0"

    executeCommonAssertions
    assertCeSampleDataNotInstalled
    assertElasticSearchDisabled
    # There is no automatic switch to EE on project initialization for Windows hosts
    assertMagentoEditionIsCE
    assertTestsConfigured
}

## Call and Run all Tests
. "lib/shunit2-2.1.6/src/shunit2"
