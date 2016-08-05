#! /usr/bin/env bash

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

function testNoCustomConfig()
{
    current_config_name="no_custom_config"
    current_codebase="ce"
    installEnvironment
    assertVarnishDisabled
    executeCommonAssertions
    assertMagentoEditionIsCE
    assertCeSampleDataNotInstalled
}

function testEeWithElasticSearchAndSampleData()
{
    current_config_name="ee_with_elastic_search_and_sample_data"
    current_codebase="ee_with_sample_data"

    installEnvironment
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
}

function testUpgradeNoCustomConfig()
{
    current_config_name="upgrade_no_custom_config"
    current_codebase="ce"
    installEnvironmentWithUpgrade
    executeCommonAssertions
    assertCeSampleDataNotInstalled
}

function testCePreferSourceVarnishEnabled()
{
    current_config_name="ce_prefer_source_varnish_enabled"
    current_codebase="ce"
    installEnvironment
    assertVarnishEnabled
    executeCommonAssertions
    assertCeSampleDataNotInstalled
}

function testCePhp5WithSampleData()
{
    current_config_name="ce_php5_sample_data"
    current_codebase="ce_with_sample_data"
    installEnvironment
    executeCommonAssertions
    assertCeSampleDataInstalled
    assertEeSampleDataNotInstalled
}

function testEeNoNfs()
{
    current_config_name="ee_no_nfs"
    current_codebase="ee"

    # TODO: change globally when https://github.com/paliarush/magento2-vagrant-for-developers/issues/58 is unblocked
    vagrant_dir="${tests_dir}/tmp/test/magento2 vagrant"

    installEnvironment
    executeCommonAssertions
    assertCeSampleDataNotInstalled
    assertElasticSearchDisabled
    # There is no automatic switch to EE on project initialization for Windows hosts
    assertMagentoEditionIsCE
}

## Call and Run all Tests
. "lib/shunit2-2.1.6/src/shunit2"
