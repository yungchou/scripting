# Use a deployment button to deploy templates from GitHub repository
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-azure-button

#----------
# REST API
#----------
# Deploy resources with ARM templates and Azure Resource Manager REST API
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-rest

##########################################
# Deployment scope (based on the command)
##########################################

# To deploy to a resource group
PUT https://management.azure.com/subscriptions/{subscriptionId}/resourcegroups/{resourceGroupName}/providers/Microsoft.Resources/deployments/{deploymentName}?api-version=2020-06-01

# To deploy to a subscription
PUT https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Resources/deployments/{deploymentName}?api-version=2020-06-01
For more information about subscription level deployments, see Create resource groups and resources at the subscription level.

# To deploy to a management group
PUT https://management.azure.com/providers/Microsoft.Management/managementGroups/{groupId}/providers/Microsoft.Resources/deployments/{deploymentName}?api-version=2020-06-01

# For more information about management group level deployments
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-management-group?tabs=azure-cli

# To deploy to a tenant
PUT https://management.azure.com/providers/Microsoft.Resources/deployments/{deploymentName}?api-version=2020-06-01




# https://github.com/Azure/azure-quickstart-templates/tree/master/201-encrypt-running-windows-vm-without-aad

# https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2F201-encrypt-running-windows-vm-without-aad%2Fazuredeploy.json

To view MD file in VS Code
- npm install -g express
- Right-click the file tab and Open Preview, or Ctrl+Shift+v

ARM Viewer for VS Code
- Click the eye symbol
- or Ctrl+Shift+q