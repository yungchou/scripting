/* 
Azure Storage Library for JavaScript
https://docs.microsoft.com/en-us/javascript/api/overview/azure/storage-overview?view=azure-node-latest
npm install @azure/arm-storage
*/

const msRestAzure = require("ms-rest-azure");
const storageManagementClient = require("azure-arm-storage");

const subscriptionId = "your-subscription-id";

msRestAzure
	.interactiveLogin()
	.then((credentials) => {
		const client = new storageManagementClient(credentials, subscriptionId);
		return client.storageAccounts.list();
	})
	.then((accounts) => console.dir(accounts, { depth: null, colors: true }))
	.catch((err) => console.log(err));
