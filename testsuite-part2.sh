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

function setUp()
{
    debug_vagrant_project=0
    skip_codebase_stash=0
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

function testCePreferSourceVarnishEnabled()
{
    current_config_name="ce_prefer_source_varnish_enabled"
    current_codebase="ce"
    debug_vagrant_project=1
    installEnvironment

    assertVarnishEnabled
    executeCommonAssertions
    assertCeSampleDataNotInstalled
    assertTestsConfigured

    virtualMachineSuspendAndResume
    executeCommonAssertions

    hardReboot
    executeCommonAssertions
}

function testCe21Php5WithSampleData()
{
    current_config_name="ce21_php5_sample_data_default_mode"
    current_codebase="ce21_with_sample_data"
    installEnvironment
    executeCommonAssertions
    assertCeSampleDataInstalled
    assertEeSampleDataNotInstalled
    assertTestsConfigured
}

function testUpgradeComposerProject()
{
    current_config_name="upgrade_composer_project"
    skip_codebase_stash=1
    installEnvironment
    upgradeComposerBasedMagento
    executeCommonAssertions
}

## Call and Run all Tests
. "lib/shunit2-2.1.6/src/shunit2"
