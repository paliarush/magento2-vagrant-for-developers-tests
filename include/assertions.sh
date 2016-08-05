#! /usr/bin/env bash

## Assertion groups

function executeCommonAssertions()
{
    assertPhpStormConfigured

    # Make sure Magento was installed and is accessible
    assertMagentoInstalledSuccessfully
    assertMagentoFrontendAccessible
    assertMagentoCliWorks

    # Make sure Magento is still accessible after restarting services
    assertMysqlRestartWorks
    assertApacheRestartWorks
    assertMagentoFrontendAccessible

    # Make sure Magento reinstall script works
    assertMagentoReinstallWorks
    assertMagentoFrontendAccessible

    assertEmailLoggingWorks

    # Check if varnish can be enabled/disabled
    assertVarnishEnablingWorks
    assertVarnishDisablingWorks

    # Test search
    createSimpleProduct
    assertSearchWorks
}

## Assertions

function assertMagentoInstalledSuccessfully()
{
    echo "${blue}## assertMagentoInstalledSuccessfully${regular}"
    echo "## assertMagentoInstalledSuccessfully" >>${current_log_file_path}
    cd ${tests_dir}
    output_log="$(cat ${current_log_file_path})"
    pattern="Access storefront at ([a-zA-Z0-9/:\.]+).*"
    if [[ ! ${output_log} =~ ${pattern} ]]; then
        fail "Magento was not installed successfully (Frontend URL is not available in the init script output)"
    fi
    current_magento_base_url=${BASH_REMATCH[1]}
}

function assertMagentoFrontendAccessible()
{
    echo "${blue}## assertMagentoFrontendAccessible${regular}"
    echo "## assertMagentoFrontendAccessible" >>${current_log_file_path}
    cd ${tests_dir}
    magento_home_page_content="$(curl -sL ${current_magento_base_url})"
    pattern="Magento. All rights reserved."
    assertTrue "Magento was installed but main page is not accessible. URL: '${current_magento_base_url}'" '[[ ${magento_home_page_content} =~ ${pattern} ]]'
}

function assertMagentoEditionIsCE()
{
    echo "${blue}## assertMagentoEditionIsCE${regular}"
    echo "## assertMagentoEditionIsCE" >>${current_log_file_path}
    cd ${tests_dir}
    admin_token="$(curl -sb -X POST "${current_magento_base_url}rest/V1/integration/admin/token" \
        -H "Content-Type:application/json" \
        -d '{"username":"admin", "password":"123123q"}')"
    rest_schema="$(curl -sb -x GET "${current_magento_base_url}rest/default/schema" -H "Authorization:Bearer ${admin_token}")"
    pattern='"title":"Magento Community"'
    assertTrue 'Current edition is not Community.' '[[ ${rest_schema} =~ ${pattern} ]]'
}

function assertMagentoEditionIsEE()
{
    echo "${blue}## assertMagentoEditionIsEE${regular}"
    echo "## assertMagentoEditionIsEE" >>${current_log_file_path}
    cd ${tests_dir}
    admin_token="$(curl -sb -X POST "${current_magento_base_url}rest/V1/integration/admin/token" \
        -H "Content-Type:application/json" \
        -d '{"username":"admin", "password":"123123q"}')"
    rest_schema="$(curl -sb -x GET "${current_magento_base_url}rest/default/schema" -H "Authorization:Bearer ${admin_token}")"
    pattern='"title":"Magento Enterprise"'
    assertTrue 'Current edition is not Enterprise.' '[[ ${rest_schema} =~ ${pattern} ]]'
}

function assertMysqlRestartWorks()
{
    echo "${blue}## assertMysqlRestartWorks${regular}"
    echo "## assertMysqlRestartWorks" >>${current_log_file_path}
    cd "${vagrant_dir}"
    cmd_output="$(vagrant ssh -c 'sudo service mysql restart' >>${current_log_file_path} 2>&1)"
    pattern="mysql start/running, process [0-9]+"
    output_log="$(tail -n2 ${current_log_file_path})"
    assertTrue 'MySQL server restart attempt failed' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertApacheRestartWorks()
{
    echo "${blue}## assertApacheRestartWorks${regular}"
    echo "## assertApacheRestartWorks" >>${current_log_file_path}
    cd "${vagrant_dir}"
    cmd_output="$(vagrant ssh -c 'sudo service apache2 restart' >>${current_log_file_path} 2>&1)"
    pattern="\[ OK \]"
    output_log="$(tail -n2 ${current_log_file_path})"
    assertTrue 'Apache restart attempt failed' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertMagentoReinstallWorks()
{
    echo "${blue}## assertMagentoReinstallWorks${regular}"
    echo "## assertMagentoReinstallWorks" >>${current_log_file_path}
    cd "${vagrant_dir}"
    bash m-reinstall >>${current_log_file_path} 2>&1
    pattern="Access storefront at ([a-zA-Z0-9/:\.]+).*"
    output_log="$(tail -n5 ${current_log_file_path})"
    assertTrue 'Magento reinstallation failed (Frontend URL is not available in the output)' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertMagentoSwitchToEeWorks()
{
    echo "${blue}## assertMagentoSwitchToEeWorks${regular}"
    echo "## assertMagentoSwitchToEeWorks" >>${current_log_file_path}
    cd "${vagrant_dir}"
    bash m-switch-to-ee -f >>${current_log_file_path} 2>&1
    pattern="Access storefront at ([a-zA-Z0-9/:\.]+).*"
    output_log="$(tail -n5 ${current_log_file_path})"
    assertTrue 'Magento switch to EE failed (Frontend URL is not available in the output)' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertMagentoSwitchToCeWorks()
{
    echo "${blue}## assertMagentoSwitchToCeWorks${regular}"
    echo "## assertMagentoSwitchToCeWorks" >>${current_log_file_path}
    cd "${vagrant_dir}"
    bash m-switch-to-ce -f >>${current_log_file_path} 2>&1
    pattern="Access storefront at ([a-zA-Z0-9/:\.]+).*"
    output_log="$(tail -n5 ${current_log_file_path})"
    assertTrue 'Magento switch to CE failed (Frontend URL is not available in the output)' '[[ ${output_log} =~ ${pattern} ]]'
}

function assertMagentoCliWorks()
{
    echo "${blue}## assertMagentoCliWorks${regular}"
    echo "## assertMagentoCliWorks" >>${current_log_file_path}
    cd "${vagrant_dir}"
    bash m-bin-magento list >>${current_log_file_path} 2>&1
    pattern="theme:uninstall"
    output_log="$(tail -n2 ${current_log_file_path})"
    assertTrue "${red}Magento CLI does not work.${regular}" '[[ ${output_log} =~ ${pattern} ]]'
}

function assertEmailLoggingWorks()
{
    echo "${blue}## assertEmailLoggingWorks${regular}"
    echo "## assertEmailLoggingWorks" >>${current_log_file_path}
    curl -X POST -F 'email=subscriber@example.com' "${current_magento_base_url}/newsletter/subscriber/new/"

    # Check if email is logged and identify its path
    list_of_logged_emails="$(ls -l "${vagrant_dir}/log/email")"
    pattern="([^ ]+Newsletter subscription success\.html)"
    if [[ ! ${list_of_logged_emails} =~ ${pattern} ]]; then
        fail "Email logging is broken (newsletter subscription email is not logged to 'vagrant-magento/log/email')"
    fi
    email_file_name=${BASH_REMATCH[1]}
    email_file_path="${vagrant_dir}/log/email/${email_file_name}"

    # Make sure content of the email is an HTML
    email_content="$(cat "${email_file_path}")"
    pattern="^<!DOCTYPE html PUBLIC.*</html>$"
    assertTrue 'Email is logged, but content is invalid' '[[ ${email_content} =~ ${pattern} ]]'
}

function assertVarnishEnablingWorks()
{
    echo "${blue}## assertVarnishEnablingWorks${regular}"
    echo "## assertVarnishEnablingWorks" >>${current_log_file_path}

    cd "${vagrant_dir}"
    bash m-varnish enable >>${current_log_file_path} 2>&1
    assertVarnishEnabled
    assertMagentoFrontendAccessible
}

function assertVarnishEnabled()
{
    echo "${blue}## assertVarnishEnabled${regular}"
    echo "## assertVarnishEnabled" >>${current_log_file_path}

    listenerOnPort80="$(vagrant ssh -c 'sudo netstat -tulnp | grep ':::80[^0-9]'')"
    assertTrue 'Varnish is not listening on port 80' '[[ ${listenerOnPort80} =~ varnishd ]]'

    listenerOnPort8080="$(vagrant ssh -c 'sudo netstat -tulnp | grep ':::8080[^0-9]'')"
    assertTrue 'Apache is not listening on port 8080' '[[ ${listenerOnPort8080} =~ apache2 ]]'
}

function assertVarnishDisablingWorks()
{
    echo "${blue}## assertVarnishDisablingWorks${regular}"
    echo "## assertVarnishDisablingWorks" >>${current_log_file_path}

    cd "${vagrant_dir}"
    bash m-varnish disable >>${current_log_file_path} 2>&1

    assertVarnishDisabled
    assertMagentoFrontendAccessible
}

function assertVarnishDisabled()
{
    echo "${blue}## assertVarnishDisabled${regular}"
    echo "## assertVarnishDisabled" >>${current_log_file_path}

    cd "${vagrant_dir}"
    listenerOnPort80="$(vagrant ssh -c 'sudo netstat -tulnp | grep ':::80[^0-9]'')"
    assertTrue 'Apache is not listening on port 80' '[[ ${listenerOnPort80} =~ apache2 ]]'

    listenerOnPort8080="$(vagrant ssh -c 'sudo netstat -tulnp | grep ':::8080[^0-9]'')"
    assertFalse 'Varnish shout not listen on port 8080' '[[ ${listenerOnPort8080} =~ varnishd ]]'
}

function assertNoErrorsInLogs()
{
    echo "${blue}## assertNoErrorsInLogs${regular}"
    echo "## assertNoErrorsInLogs" >>${current_log_file_path}

    grep_cannot="$(cat "${current_log_file_path}" | grep -i "cannot" | grep -iv "unload module vboxguest" | grep -iv "load Xdebug - it was already loaded" | grep -iv "Directory not empty")"
    count_cannot="$(echo ${grep_cannot} | grep -ic "cannot")"
    assertTrue "Errors found in log file:
        ${grep_cannot}" '[[ ${count_cannot} -eq 0 ]]'

    grep_error="$(cat "${current_log_file_path}" | grep -i "error" | grep -iv "errors = Off|display" | grep -iv "error_reporting = E_ALL" | grep -iv "assertNoErrorsInLogs" | grep -iv "shared folder errors")"
    count_error="$(echo ${grep_error} | grep -ic "error")"
    assertTrue "Errors found in log file:
        ${grep_error}" '[[ ${count_error} -eq 0 ]]'
}

function assertPhpStormConfigured()
{
    echo "${blue}## assertPhpStormConfigured${regular}"
    echo "## assertPhpStormConfigured" >>${current_log_file_path}

    deployment_config_path="${vagrant_dir}/.idea/deployment.xml"
    misc_config_path="${vagrant_dir}/.idea/misc.xml"
    assertTrue 'PhpStorm was not configured (deployment.xml is missing)' '[[ -f ${deployment_config_path} ]]'
    assertTrue 'PhpStorm was not configured (misc.xml is missing)' '[[ -f ${misc_config_path} ]]'
    assertTrue 'PhpStorm was not configured (php.xml is missing)' '[[ -f ${vagrant_dir}/.idea/php.xml ]]'
    assertTrue 'PhpStorm was not configured (vcs.xml is missing)' '[[ -f ${vagrant_dir}/.idea/vcs.xml ]]'
    assertTrue 'PhpStorm was not configured (webServers.xml is missing)' '[[ -f ${vagrant_dir}/.idea/webServers.xml ]]'

    deployment_config_content="$(cat "${deployment_config_path}")"
    assertTrue 'PhpStorm configured incorrectly. deployment.xml config is invalid' '[[ ${deployment_config_content} =~ \$PROJECT_DIR\$/magento2ce/app/etc ]]'

    misc_config_content="$(cat "${misc_config_path}")"
    assertTrue 'PhpStorm configured incorrectly. misc.xml config is invalid' '[[ ${misc_config_content} =~ urn:magento:module:Magento_Cron:etc/crontab.xsd ]]'
}

function assertElasticSearchEnabled()
{
    echo "${blue}## assertElasticSearchEnabled${regular}"
    echo "## assertElasticSearchEnabled" >>${current_log_file_path}

    cd "${vagrant_dir}"
    elasticSearchHealth="$(vagrant ssh -c 'curl -i http://127.0.0.1:9200/_cluster/health')"
    assertTrue "ElasticSearch server is down:
        ${elasticSearchHealth}" '[[ ${elasticSearchHealth} =~ \"status\":\"(green|yellow)\" ]]'

    listOfIndexes="$(vagrant ssh -c 'curl -i http://127.0.0.1:9200/_cat/indices?v')"
    assertTrue "Products index is not available in ElasticSearch:
        ${listOfIndexes}" '[[ ${listOfIndexes} =~ magento2_product ]]'

    assertSearchWorks
}

function assertElasticSearchDisabled()
{
    echo "${blue}## assertElasticSearchDisabled${regular}"
    echo "## assertElasticSearchDisabled" >>${current_log_file_path}

    cd "${vagrant_dir}"
    elasticSearchHealth="$(vagrant ssh -c 'curl -i http://127.0.0.1:9200/_cluster/health')"
    assertTrue "ElasticSearch server is down:
        ${elasticSearchHealth}" '[[ ${elasticSearchHealth} =~ \"status\":\"(green|yellow)\" ]]'

    listOfIndexes="$(vagrant ssh -c 'curl -i http://127.0.0.1:9200/_cat/indices?v')"
    assertTrue "Products index must not be available in ElasticSearch:
        ${listOfIndexes}" '[[ ! ${listOfIndexes} =~ magento2_product ]]'

    assertSearchWorks
}

function assertSearchWorks()
{
    echo "${blue}## assertSearchWorks${regular}"
    echo "## assertSearchWorks" >>${current_log_file_path}

    cd "${vagrant_dir}"
    productSearchResult="$(curl -sb -x GET "${current_magento_base_url}catalogsearch/result/?q=Test")"
    # Search for test product price on the page
    pattern="$22.00"
    assertTrue "Catalog search does not work." '[[ ${productSearchResult} =~ ${pattern} ]]'
}

function assertElasticSearchEnablingWorks()
{
    echo "${blue}## assertElasticSearchEnablingWorks${regular}"
    echo "## assertElasticSearchEnablingWorks" >>${current_log_file_path}

    cd "${vagrant_dir}"
    bash m-search-engine elasticsearch >>${current_log_file_path} 2>&1
    refreshSearchIndexes
    assertElasticSearchEnabled
}

function assertElasticSearchDisablingWorks()
{
    echo "${blue}## assertElasticSearchDisablingWorks${regular}"
    echo "## assertElasticSearchDisablingWorks" >>${current_log_file_path}

    cd "${vagrant_dir}"
    bash m-search-engine mysql >>${current_log_file_path} 2>&1
    refreshSearchIndexes
    assertElasticSearchDisabled
}

function assertCeSampleDataInstalled()
{
    echo "${blue}## assertCeSampleDataInstalled${regular}"
    echo "## assertCeSampleDataInstalled" >>${current_log_file_path}

    cd "${vagrant_dir}"
    productDetailsPage="$(curl -sb -x GET "${current_magento_base_url}wayfarer-messenger-bag.html")"
    # Search for product SKU on the page
    pattern="24-MB05"
    assertTrue "Sample data is not installed." '[[ ${productDetailsPage} =~ ${pattern} ]]'
}

function assertEeSampleDataInstalled()
{
    echo "${blue}## assertEeSampleDataInstalled${regular}"
    echo "## assertEeSampleDataInstalled" >>${current_log_file_path}

    cd "${vagrant_dir}"
    productDetailsPage="$(curl -sb -x GET "${current_magento_base_url}joust-duffle-bag.html")"
    # Search for Related Products on the page, which are populated by EE sample data
    pattern="Affirm Water Bottle"
    assertTrue "EE sample data not installed." '[[ ${productDetailsPage} =~ ${pattern} ]]'
}

function assertEeSampleDataNotInstalled()
{
    echo "${blue}## assertEeSampleDataNotInstalled${regular}"
    echo "## assertEeSampleDataNotInstalled" >>${current_log_file_path}

    cd "${vagrant_dir}"
    productDetailsPage="$(curl -sb -x GET "${current_magento_base_url}joust-duffle-bag.html")"
    # Search for Related Products on the page, which are populated by EE sample data
    pattern="Affirm Water Bottle"
    assertTrue "EE sample data is installed, when should not be." '[[ ! ${productDetailsPage} =~ ${pattern} ]]'
}

function assertCeSampleDataNotInstalled()
{
    echo "${blue}## assertCeSampleDataNotInstalled${regular}"
    echo "## assertCeSampleDataNotInstalled" >>${current_log_file_path}

    cd "${vagrant_dir}"
    productDetailsPage="$(curl -sb -x GET "${current_magento_base_url}wayfarer-messenger-bag.html")"
    pattern="The page you requested was not found"
    assertTrue "Sample data is installed, when should not be." '[[ ${productDetailsPage} =~ ${pattern} ]]'
}
