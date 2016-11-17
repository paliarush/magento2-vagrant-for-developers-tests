#! /usr/bin/env bash

source include/configuration.sh
source include/global_variables.sh
source include/helpers.sh
source include/assertions.sh

function oneTimeSetUp()
{
    clearLogs
    current_config_name="no_custom_config"
    current_codebase="ce"
    debug_vagrant_project=0
    installEnvironment
}

function oneTimeTearDown()
{
    if [[ ${delete_test_project_on_tear_down} -eq 1 ]]; then
        stashLogs
        stashMagentoCodebase
        clearTestTmp
    fi

    # TODO: change globally when https://github.com/paliarush/magento2-vagrant-for-developers/issues/58 is unblocked
    vagrant_dir="${tests_dir}/tmp/test/magento2-vagrant"
}

function testVarnishStatusAfterInstallation()
{
    assertVarnishDisabled
}

## BEGIN Common Tests

#source include/common_tests.sh

function testPhpStormConfiguration()
{
    assertPhpStormConfigured
}

function testMagentoFrontendAfterInitialization()
{
    # Make sure Magento was installed and is accessible
    assertMagentoInstalledSuccessfully
    assertMagentoFrontendAccessible
}

function testMagentoCli()
{
    assertMagentoCliWorks
}

function testMysqlRestart()
{
    assertMysqlRestartWorks
}

function testApacheRestart()
{
    assertApacheRestartWorks
}

function testMagentoFrontendAfterServicesRestart()
{
    # Make sure Magento is still accessible after restarting services
    assertMagentoFrontendAccessible
}

function testReinstall()
{
    assertMagentoReinstallWorks
}

function testMagentoFrontendAfterReinstall()
{
    assertMagentoFrontendAccessible
}

function testEmailLogging()
{
    assertEmailLoggingWorks
}

function testVarnishEnabling()
{
    assertVarnishEnablingWorks
}

function testVarnishDisabling()
{
    assertVarnishDisablingWorks
}

function testSearch()
{
    createSimpleProduct
    assertSearchWorks
}

### END Common Tests

function testCurrentEdition()
{
    assertMagentoEditionIsCE
}

function testSampleDataStatus()
{
    assertCeSampleDataNotInstalled
}

function testTestsConfiguration()
{
    assertTestsConfigured
}

function testDebugConfiguration()
{
    assertDebugConfigurationWork
}

function testRedisCacheStatus()
{
    assertRedisCacheIsEnabled
}

function testErrorLogs()
{
    assertNoErrorsInLogs
}

## Call and Run all Tests
. "lib/shunit2-2.1.6/src/shunit2"
