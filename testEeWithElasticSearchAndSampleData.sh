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

function testEeWithElasticSearchAndSampleData()
{
    current_config_name="ee_with_elastic_search_and_sample_data"
    current_codebase="ee_with_sample_data_2_1"

    installEnvironment

    assertSourceCodeIsFromBranch "${vagrant_dir}/magento2ce" "2.1"
    assertSourceCodeIsFromBranch "${vagrant_dir}/magento2ce/magento2ee" "2.1"
    assertSourceCodeIsFromBranch "${vagrant_dir}/magento2ce/magento2ce-sample-data" "2.1"
    assertSourceCodeIsFromBranch "${vagrant_dir}/magento2ce/magento2ee-sample-data" "2.1"

    executeCommonAssertions
    assertCeSampleDataInstalled
    assertEeSampleDataInstalled
    assertMagentoEditionIsEE

    assertElasticSearchEnabled
    assertElasticSearchDisablingWorks
    assertElasticSearchEnablingWorks

    assertMagentoSwitchToCeWorks
    assertMagentoFrontendAccessible
    assertMagentoEditionIsCE
    assertCeSampleDataInstalled
    assertEeSampleDataNotInstalled

    assertMagentoSwitchToEeWorks
    assertMagentoFrontendAccessible
    assertMagentoEditionIsEE
    assertCeSampleDataInstalled
    assertEeSampleDataInstalled

    hardReboot
    executeCommonAssertions
    assertTestsConfigured
}

## Call and Run all Tests
. "lib/shunit2-2.1.6/src/shunit2"
