#! /usr/bin/env bash

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

function assertEmailLoggingWorks()
{
    echo "## assertEmailLoggingWorks"
    echo "## assertEmailLoggingWorks" >>${current_log_file_path}
    curl -X POST -F 'email=subscriber@example.com' "${current_magento_base_url}/newsletter/subscriber/new/"

    # Check if email is logged and identify its path
    list_of_logged_emails="$(ls -l ${vagrant_dir}/log/email)"
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
    echo "## assertVarnishEnablingWorks"
    echo "## assertVarnishEnablingWorks" >>${current_log_file_path}

    cd ${vagrant_dir}
    bash m-varnish enable >>${current_log_file_path} 2>&1
    assertVarnishEnabled
    assertMagentoAccessible
}

function assertVarnishEnabled()
{
    echo "## assertVarnishEnabled"
    echo "## assertVarnishEnabled" >>${current_log_file_path}

    listenerOnPort80="$(vagrant ssh -c 'sudo netstat -tulnp | grep ':::80[^0-9]'')"
    assertTrue 'Varnish is not listening on port 80' '[[ ${listenerOnPort80} =~ varnishd ]]'

    listenerOnPort8080="$(vagrant ssh -c 'sudo netstat -tulnp | grep ':::8080[^0-9]'')"
    assertTrue 'Apache is not listening on port 8080' '[[ ${listenerOnPort8080} =~ apache2 ]]'
}

function assertVarnishDisablingWorks()
{
    echo "## assertVarnishDisablingWorks"
    echo "## assertVarnishDisablingWorks" >>${current_log_file_path}

    cd ${vagrant_dir}
    bash m-varnish disable >>${current_log_file_path} 2>&1

    assertVarnishDisabled
    assertMagentoAccessible
}

function assertVarnishDisabled()
{
    echo "## assertVarnishDisabled"
    echo "## assertVarnishDisabled" >>${current_log_file_path}

    listenerOnPort80="$(vagrant ssh -c 'sudo netstat -tulnp | grep ':::80[^0-9]'')"
    assertTrue 'Apache is not listening on port 80' '[[ ${listenerOnPort80} =~ apache2 ]]'

    listenerOnPort8080="$(vagrant ssh -c 'sudo netstat -tulnp | grep ':::8080[^0-9]'')"
    assertFalse 'Varnish shout not listen on port 8080' '[[ ${listenerOnPort8080} =~ varnishd ]]'
}
