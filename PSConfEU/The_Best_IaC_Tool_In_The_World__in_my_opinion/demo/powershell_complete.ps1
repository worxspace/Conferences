Import-Module pspulumiyaml.azurenative.resources
Import-Module pspulumiyaml.azurenative.storage
. ./Deploy-StorageAccountAsApprovedByCompanyInfrastructureSecurity

New-PulumiYamlFile {

    $storageAccounts = Deploy-StorageAccountAsApprovedByCompanyInfrastructureSecurity -ProjectName "psconfpulumidemo"

    foreach ($location in $storageAccounts.keys) {

        $resourceGroup = $storageAccounts.$location.ResourceGroup
        $storageAccount = $storageAccounts.$location.StorageAccount

        $Props = @{
            pulumiid          = "website-$location"
            accountName       = $storageAccount.reference("name")
            resourceGroupName = $storageAccount.reference("name")
            indexDocument     = "index.html"
            error404Document  = "404.html"
        }
        $website = New-AzureNativeStorageStorageAccountStaticWebsite @Props

        @(
            @{
                Name = "index.html"
                Type = "text/html"
            },
            @{
                Name = "404.html"
                Type = "text/html"
            },
            @{
                Name = "favicon.png"
                Type = "image/png"
            }
        ) | ForEach-Object {
            $Props = @{
                pulumiid          = "$($_.Name)-$location"
                accountName       = $storageAccount.reference("name")
                resourceGroupName = $resourceGroup.reference("name")
                ContainerName     = $website.reference("containerName")
                contentType       = $_.Type
                Type              = "Block"
                Source            = New-PulumiFileAsset "./www/$($_.Name)"
            }
            $null = New-AzureNativeStorageStorageBlob @Props
        }

        $keys = Invoke-AzureNativeStorageListStorageAccountKeys -accountName $storageAccount.reference("name") -resourceGroupName $resourceGroup.reference("name")

        New-PulumiOutput -Name "website-url-$location" -Value $storageAccount.reference("primaryEndpoints.web")
        New-PulumiOutput -Name "primarykey-$location" -Value $keys.reference("keys[0].value")
    }
}
