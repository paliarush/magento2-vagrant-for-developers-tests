#! /usr/bin/env bash

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
