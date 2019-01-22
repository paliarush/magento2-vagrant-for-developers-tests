# Tests for Magento 2 Kubernetes DebBox project

Current project contains CLI functional tests for [Magento 2 Kubernetes DevBox](https://github.com/magento/magento2-kubernetes-devbox) project.

## To run the tests:

 1. Make sure that your host meets requirements listed [here](https://github.com/magento/magento2-kubernetes-devbox#requirements)
 1. Copy [configuration.sh.dist](include/configuration.sh.dist) to `include/configuration.sh` and make necessary changes
 1. Copy [auth.json.dist](include/auth.json.dist) to `include/auth.json` and add valid keys
 1. Run [testsuite.sh](testsuite.sh) in bash
 1. You may need to configure NFS after the very first run. If the test failed, there should be an error message with the instructions in the log file.
