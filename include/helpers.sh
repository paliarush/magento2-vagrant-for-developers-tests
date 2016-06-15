#! /usr/bin/env bash

function installEnvironment()
{
    stashMagentoCodebase
    clearTestTmp
    downloadVagrantProject
    unstashMagentoCodebase
    configureVagrantProject
    deployVagrantProject
}

function installEnvironmentWithUpgrade()
{
    stashMagentoCodebase
    clearTestTmp
    downloadBaseVersionOfVagrantProject
    unstashMagentoCodebase
    configureVagrantProject
    deployVagrantProject
    upgradeVagrantProject
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

    assertEmailLoggingWorks

    # Check if varnish can be enabled/disabled
    assertVarnishEnablingWorks
    assertVarnishDisablingWorks
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
    git clone ${vagrant_project_repository_url} ${vagrant_dir} >>${current_log_file_path} 2>&1
    cd ${vagrant_dir}
    git checkout ${vagrant_project_branch} >>${current_log_file_path} 2>&1
}

function downloadBaseVersionOfVagrantProject()
{
    echo "## downloadBaseVersionOfVagrantProject"
    echo "## downloadBaseVersionOfVagrantProject" >>${current_log_file_path}
    cd ${tests_dir}
    git clone git@github.com:paliarush/magento2-vagrant-for-developers.git ${vagrant_dir} >>${current_log_file_path} 2>&1
    cd ${vagrant_dir}
    git checkout tags/v2.0.0 >>${current_log_file_path} 2>&1
    # Make sure that older box version is used
    sed -i.back 's|config.vm.box_version = "~> 1.0"|config.vm.box_version = "= 1.0"|g' "${vagrant_dir}/Vagrantfile" >>${current_log_file_path} 2>&1
    echo '{"github-oauth": {"github.com": "sampletoken"}}' >"${vagrant_dir}/etc/composer/auth.json"
}

function upgradeVagrantProject()
{
    echo "## upgradeVagrantProject"
    echo "## upgradeVagrantProject" >>${current_log_file_path}
    # Reset changes done to box version requirements
    git checkout "${vagrant_dir}/Vagrantfile" >>${current_log_file_path} 2>&1
    cd ${vagrant_dir}
    git remote add repository-under-test ${vagrant_project_repository_url} >>${current_log_file_path} 2>&1
    git fetch repository-under-test >>${current_log_file_path} 2>&1
    git checkout -b branch-under-test repository-under-test/${vagrant_project_branch} >>${current_log_file_path} 2>&1
    vagrant reload >>${current_log_file_path} 2>&1
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