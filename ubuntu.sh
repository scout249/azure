echo "Enter the Resource Group name:" &&
read resourceGroupName &&
echo "Enter the location (i.e. westus2):" &&
read location &&
echo "Enter the administrator username:" &&
read username &&
az group create --name $resourceGroupName --location $location &&
az network vnet create --resource-group $resourceGroupName --name myVnet --address-prefix 192.168.0.0/16 --subnet-name mySubnet --subnet-prefix 192.168.1.0/24 &&
az network public-ip create --resource-group $resourceGroupName --name myPublicIP &&
az network nsg create --resource-group $resourceGroupName --name myNetworkSecurityGroup &&
az network nsg rule create --resource-group $resourceGroupName --nsg-name myNetworkSecurityGroup --name myNetworkSecurityGroupRuleSSH --protocol tcp --priority 1000 --destination-port-range 22 --access allow &&
az network nsg rule create --resource-group $resourceGroupName --nsg-name myNetworkSecurityGroup --name myNetworkSecurityGroupRuleWeb --protocol tcp --priority 1001 --destination-port-range 80 --access allow &&
az network nic create --resource-group $resourceGroupName --name myNic --vnet-name myVnet --subnet mySubnet --public-ip-address myPublicIP --network-security-group myNetworkSecurityGroup &&
az vm create --resource-group $resourceGroupName --name myVM --location $location myAvailabilitySet --nics myNic --image Ubuntu2204 --admin-username $username --generate-ssh-keys &&
az vm show --resource-group $resourceGroupName --name "myVM" --show-details --query publicIps --output tsv
