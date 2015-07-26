# Adds the base cmdlets
Add-PSSnapin VMware.VimAutomation.Core

# 環境設定
$vcserver = "192.168.3.100"
$vcuser = "administrator"
$vcpassword = "VMware1!"
$nfshost = "192.168.5.99"
$nfspath1 = "/mnt/DroboFS/Shares/NFS"

#ISOメディアパス
#$ISOPath = "[NFS-Remote1] ISO/ESXi/5.1.0U2/VMware-VMvisor-Installer-5.1.0.update02-1483097.x86_64.iso"
#$ISOPath = "[NFS-Remote1] ISO/ESXi/5.1.0U2/CUSTOM-VMware-VMvisor-Installer-5.1.0.update02-1483097.x86_64.iso"
#$ISOPath = "[NFS-Remote1] ISO/ESXi/5.5.0/VMware-VMvisor-Installer-5.5.0-1331820.x86_64.iso"
#$ISOPath = "[NFS-Remote1] ISO/ESXi/5.5.0U1/ESXi 5.5 Update 1 ISO image (Includes VMware Tools)/VMware-VMvisor-Installer-5.5.0.update01-1623387.x86_64.iso"
#$ISOPath = "[NFS-Remote1] ISO/ESXi/5.5.0U2/VMware-VMvisor-Installer-5.5.0.update02-2068190.x86_64.iso"
$ISOPath = "[NFS-Remote1] ISO/ESXi/5.5.0U2/CUSTOM-VMware-VMvisor-Installer-5.5.0.update02-2068190.x86_64.iso"
#$ISOPath = "[NFS-Remote1] ISO/ESXi/5.1.0U3/VMware-VMvisor-Installer-5.1.0.update03-2323236.x86_64.iso"

# vCenterへの接続
Write-Host "Connecting to vCenter Server" -ForegroundColor green
Connect-VIServer -Server $vcserver -User $vcuser -Password $vcpassword

# VMの名前
$VMName = Read-Host 'What is the name of VM?'

# ターゲット・ホストの定義
$TargetHost = Read-Host 'Which host would you like to create the VM on?'

# ターゲット・リソースプールの定義
$TargetRP = Read-Host 'Which resource pool would you like to create the VM on?'

#ターゲット・ホストのデータストア取得
Write-Host ""
            Write-Host "These are the available datastores:"
            Write-Host "Name`t`tFreeSpaceMB`tCapacityMB"
            Write-Host "----`t`t----------`t----------"
            Get-VMHost $TargetHost | Get-Datastore | `
                  ForEach-Object {Write-Host "$($_.Name)`t$($_.FreeSpaceMB)`t`t$($_.CapacityMB)"}
                Write-Host " "

#ターゲット・データストアの定義
$TargetDatastore = Read-Host "Which datastore would you like to place the VM on?"

#　VMの作成
Write-Host "Creating a Virtual Machine" -ForegroundColor green
New-VM -Name "$VMName" -ResourcePool $TargetRP  -Datastore $TargetDatastore -Version v8 -NumCPU 4 -MemoryGB 8 -DiskGB 8 -DiskStorageFormat Thin -NetworkName "VM Network" -CD  -GuestID vmkernel5Guest
#New-VM -Name "$VMName" -ResourcePool $TargetRP  -Datastore $TargetDatastore -Version v8 -NumCPU 4 -MemoryGB 8 -DiskGB 8 -DiskStorageFormat Thin -NetworkName "PG-LAB-MGMT" -CD  -GuestID vmkernel5Guest

# NICの追加
Write-Host "Adding NICs to the Virtual Machine" -ForegroundColor green
Get-VM $VMName | New-NetworkAdapter  -NetworkName "PG-vMotion"  -StartConnected
Get-VM $VMName | New-NetworkAdapter  -NetworkName "PG-Storage"  -StartConnected
Get-VM $VMName | New-NetworkAdapter  -NetworkName "PG-Tenant"  -StartConnected
Get-VM $VMName | New-NetworkAdapter  -NetworkName "PG-Public"  -StartConnected
#Get-VM $VMName | New-NetworkAdapter  -NetworkName "PG-LAB-vMotion"  -StartConnected
#Get-VM $VMName | New-NetworkAdapter  -NetworkName "PG-Storage"  -StartConnected
#Get-VM $VMName | New-NetworkAdapter  -NetworkName "PG-LAB-Tenant"  -StartConnected
#Get-VM $VMName | New-NetworkAdapter  -NetworkName "PG-LAB-Public"  -StartConnected



# NFSマウントしていなければマウント
$hostsincluster = Get-Cluster $clustername | Get-VMHost -State "Connected" 
ForEach ($vmhost in $hostsincluster){
    if (Get-Datastore -VMHost $vmhost | Where-Object {$_.name -eq "NFS-Remote1"}) {
    # do nothing
    }
    else {    
        ""
        "Adding NFS Datastores to ESX host: $vmhost"
        "-----------------"
        "1st - Datastore $nfspath1"
        New-Datastore -VMHost $vmhost -Name "NFS-Remote1" -Nfs -NfsHost $nfshost -Path $nfspath1
        }
    }
# ISOのマウント        
Write-Host "Mouting a ISO" -ForegroundColor green
Get-VM $VMName | Get-CDDrive | Set-CDDrive -IsoPath $ISOPath -StartConnected $true -Confirm:$false

# set the guestOS string from vCenter to look for
$guestOSname = "VMware ESXi 5.x"
 
# ハードウェアアシストによる仮想化をゲストOSに公開
$vmxValue = "NestedHVEnabled"
$boolValue = "TRUE"

Write-Host "Now Setting bits for nested virtualization...`n" -ForegroundColor green 
 
$vmValue = (get-vm $VMName | get-view)
 $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
 $vmConfigSpec.$vmxValue = $boolValue
 $vmValue.ReconfigVM($vmconfigSpec)


# vmhosts.txtの作成


# kickstart　hostname.cfgの作成
#Get-NetworkAdapter -vm $VMName |?{$_.NetworkName -eq "PG-LAB-MGMT"}

# kickstart ip.cfg の作成


# VM起動
#Write-Host "Starting the VM" -ForegroundColor green
#Start-VM -VM $VMName  -Confirm:$false

# コンソールウインドウの起動
#Write-Host "Sleeping for 10 Seconds..." -ForegroundColor Green
#Start-Sleep -Seconds 10
#Get-VM  $VMName | Open-VMConsoleWindow

# vCenter 接続の切断
Write-Host "Disconnecting vCenter Server" -ForegroundColor green
Disconnect-VIServer -Server $vcserver -Confirm:$false








