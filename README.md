# Tests for Magento 2 Vagrant project

Current project contains functional tests for [Vagrant Box for Magento 2 Developers](https://github.com/paliarush/magento2-vagrant-for-developers) project.

## To run the tests:

 1. Make sure that your host meets requirements listed [here](https://github.com/paliarush/magento2-vagrant-for-developers#requirements)
 1. Copy [configuration.sh.dist](include/configuration.sh.dist) to `include/configuration.sh` and make necessary changes
 1. Copy [auth.json.dist](include/auth.json.dist) to `include/auth.json` and add valid keys
 1. Run [testsuite.sh](testsuite.sh) in bash
