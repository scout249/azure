#Create Palo Firewall

export rg="az100"
export location="westus2"

#Create Resource Group
echo "Creating Resource Group"
az group create --name $rg --location $location

#Create a Virtual Network
echo "Creating Virtual Network"
az network vnet create --resource-group $rg --location $location --name "${rg}vnet" --address-prefixes 10.0.0.0/16

#Create 3 Subnets in the virtual network. The Subnets are for the Mgmt, Untrust and Trust interfaces. 
echo "Creating Subnet"
az network vnet subnet create --resource-group $rg --vnet-name "${rg}vnet" --name mgmt --address-prefix 10.0.0.0/24
az network vnet subnet create --resource-group $rg --vnet-name "${rg}vnet" --name untrust --address-prefix 10.0.1.0/24
az network vnet subnet create --resource-group $rg --vnet-name "${rg}vnet" --name trust --address-prefix 10.0.2.0/24

#Create a Public IP Address. This will be used for the Management Interface of the VM-Series. 
echo "Creating Public IP"
az network public-ip create --name mgmtpip --resource-group $rg --location $location --dns-name mgmtdns --allocation-method Dynamic --zone 2
#Notice the --zone flag. This is because the Public IP address used on a VM-Series in an Availability Zone in Azure must have the exact same amount of zones assigned to it. 

#Create and Configure Multiple Network Interfaces
echo "Creating Network Interface"
az network nic create --resource-group $rg --location $location --name mgmtnic1 --vnet-name "${rg}vnet" --subnet mgmt
az network nic create --resource-group $rg --location $location --name untrustnic1 --vnet-name "${rg}vnet" --subnet untrust
az network nic create --resource-group $rg --location $location --name trustnic1 --vnet-name "${rg}vnet" --subnet trust 

#Create Network Security Groups
echo "Creating Network Security Group"
az network nsg create --resource-group $rg --location $location --name mgmtnsg

#Create Network Security Group Rule. This will be used for inbound management access. 
echo "Creating Network Security Group Rules"
az network nsg rule create -g $rg --nsg-name mgmtnsg -n mgmtaccess --priority 110 --source-address-prefixes Internet --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 443 --access Allow --protocol Tcp --description "Allow from specific IP address ranges on 22 and 443."

#Add Network Security Group to MGMT NIC
echo "Add NIC to NSG"
az network nic update -g $rg -n mgmtnic1 --network-security-group mgmtnsg
