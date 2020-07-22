#Create Palo Firewall

export rg="az100"
export location="westus2"
export admin="superman"
export password="P@ssw0rd$RANDOM"
export uniqueid=$RANDOM

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
az network nic create --resource-group $rg --location $location --name "mgmtnic${uniqueid}" --vnet-name "${rg}vnet" --subnet mgmt
az network nic create --resource-group $rg --location $location --name "untrustnic2${uniqueid}" --vnet-name "${rg}vnet" --subnet untrust
az network nic create --resource-group $rg --location $location --name "trustnic2${uniqueid}" --vnet-name "${rg}vnet" --subnet trust

#Create Network Security Groups
echo "Creating Network Security Group"
az network nsg create --resource-group $rg --location $location --name mgmtnsg

#Create Network Security Group Rule. This will be used for inbound management access. 
echo "Creating Network Security Group Rules"
az network nsg rule create -g $rg --nsg-name mgmtnsg -n mgmtaccess --priority 110 --source-address-prefixes Internet --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 443 --access Allow --protocol Tcp --description "Allow from specific IP address ranges on 22 and 443."

#Add Network Security Group to MGMT NIC
echo "Add NIC to NSG"
az network nic update -g $rg -n "mgmtnic${uniqueid}" --network-security-group mgmtnsg

#Attach Public IP to MGMT NIC
echo "Attach Public IP to NIC"
az network nic ip-config update -g $rg --nic-name "mgmtnic${uniqueid}" -n ipconfig1 --public-ip-address mgmtpip
#Note: At this time the VM-Series only supports a mgmt interface with public IP allocation when using availability zones.

#Create VM-Series and Assign NICs During Deployment
echo "Create Palo Alto VM"
az vm create --resource-group $rg --name vmfw1 --location $location --nics "mgmtnic${uniqueid}" "untrustnic2${uniqueid}" "trustnic2${uniqueid}" --size Standard_D3_V2 --image paloaltonetworks:vmseries1:bundle1:latest --plan-name bundle1 --plan-product vmseries1 --plan-publisher paloaltonetworks --admin-username $admin --admin-password $password --zone 2

ipaddress=$(az vm show \
  --name vmfw1 \
  --resource-group az100 \
  --show-details \
  --query [publicIps] \
  --output tsv)

echo "=========================================="
echo "Palo Alto Firewall has been created"
echo "URL: https://$ipaddress"
echo "Username: $admin"
echo "Password: $password"
echo "=========================================="
