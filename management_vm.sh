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

#Create and Configure Multiple Network Interfaces
echo "Creating Network Interface"
az network nic create --resource-group $rg --location $location --name "mgmtnic${uniqueid}" --vnet-name "${rg}vnet" --subnet mgmt
az network nic create --resource-group $rg --location $location --name "untrustnic2${uniqueid}" --vnet-name "${rg}vnet" --subnet untrust
az network nic create --resource-group $rg --location $location --name "trustnic2${uniqueid}" --vnet-name "${rg}vnet" --subnet trust 

#Create Virtual Machine
echo "Creating Virtual Machine"
az vm create \
  --resource-group $rg \
  --location $location \
  --name myVM \
  --image MicrosoftWindowsDesktop:Windows-10:20h1-pro:19041.388.2007101729 \
  --admin-username $admin \
  --admin-password $password \
  --nics "mgmtnic${uniqueid}" "untrustnic2${uniqueid}" "trustnic2${uniqueid}" \
  --size Standard_D3_V2

#Install Chrome and Putty
echo "Installing Chrome and Putty"
az vm run-command invoke --command-id RunPowerShellScript --name myvm -g $rg  \
    --scripts 'Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString("https://chocolatey.org/install.ps1"))' \
    'choco install googlechrome -y' \
    'choco install putty -y'
  
echo "=========================================="
echo "VM has been created"
echo "$ipaddress"
echo "Username: $admin"
echo "Password: $password"
echo "=========================================="
