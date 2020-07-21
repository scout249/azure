export rg="az100"
export location="westus2"
export admin="superman"
export password="P@ssw0rd$RANDOM"


#Create Resource Group
echo "Creating Resource Group"
az vm create \
  --resource-group $rg \
  --location $location \
  --name myVM \
  --image MicrosoftWindowsDesktop:Windows-10:20h1-pro:19041.388.2007101729 \
  --admin-username $admin \
  --admin-password $password
  --nics mgmtnic1 untrustnic1 trustnic1
  --size Standard_D3_V2
  
az vm run-command invoke --command-id RunPowerShellScript --name myvm -g $rg  \
    --scripts 'Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString("https://chocolatey.org/install.ps1"))' \
    'choco install googlechrome' \
    'choco install choco install putty'
  
echo "=========================================="
echo "VM has been created"
echo "$ipaddress"
echo "Username: $admin"
echo "Password: $password"
echo "=========================================="
