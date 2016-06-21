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
    echo "===TEST START==="
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
    assertVarnishDisabled
    executeCommonAssertions
    assertMagentoEditionIsCE
}

function testEe()
{
    current_config_name="ee"
    current_codebase="ee"
    installEnvironment
    executeCommonAssertions
    assertMagentoEditionIsEE
    executeEeNfsAssertions
}

function testUpgradeNoCustomConfig()
{
    current_config_name="upgrade_no_custom_config"
    current_codebase="ce"
    installEnvironmentWithUpgrade
    executeCommonAssertions
}

function testCePreferSourceVarnishEnabled()
{
    current_config_name="ce_prefer_source_varnish_enabled"
    current_codebase="ce"
    installEnvironment
    assertVarnishEnabled
    executeCommonAssertions
}

function testCePhp5()
{
    current_config_name="ce_php5"
    current_codebase="ce"
    installEnvironment
    executeCommonAssertions
}

function testEeNoNfs()
{
    current_config_name="ee_no_nfs"
    current_codebase="ee"
    installEnvironment
    executeCommonAssertions
    # There is no automatic switch to EE on project initialization for Windows hosts
    assertMagentoEditionIsCE
}

## Call and Run all Tests
. "lib/shunit2-2.1.6/src/shunit2"
