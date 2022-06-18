Import-Module pspulumiyaml.azurenative.resources
Import-Module pspulumiyaml.azurenative.storage

New-PulumiYamlFile {

    $location = 'switzerlandnorth', 'westeurope'

    $resourceGroup = New-AzureNativeResourcesResourceGroup -pulumiid "static-web-app" -resourceGroupName "ps-static-web-app" -location $location[0]

    $Props = @{
        pulumiid          = "sa"
        accountName       = "rbpspulumistweb"
        ResourceGroupName = $resourceGroup.reference("name")
        location          = $location[0]
        Kind              = "StorageV2"
        Sku               = @{
            Name = "Standard_LRS"
        }
    }
    $storageAccount = New-AzureNativeStorageStorageAccount @Props

    $Props = @{
        pulumiid          = "website"
        accountName       = $storageAccount.reference("name")
        resourceGroupName = $resourceGroup.reference("name")
        indexDocument     = "index.html"
        error404Document  = "404.html"
    }
    $website = New-AzureNativeStorageStorageAccountStaticWebsite @Props

    "index.html", "404.html" | ForEach-Object {
        $Props = @{
            pulumiid          = $_
            ResourceGroupName = $resourceGroup.reference("name")
            AccountName       = $storageAccount.reference("name")
            ContainerName     = $website.reference("containerName")
            contentType       = "text/html"
            Type              = "Block"
            Source            = New-PulumiFileAsset "./www/$_"
        }
        $null = New-AzureNativeStorageStorageBlob @Props
    }
  
    $Props = @{
        pulumiid          = "favicon.png"
        ResourceGroupName = $resourceGroup.reference("name")
        AccountName       = $storageAccount.reference("name")
        ContainerName     = $website.reference("containerName")
        contentType       = "image/png"
        Type              = "Block"
        Source            = New-PulumiFileAsset "./www/favicon.png"
    }
    $null = New-AzureNativeStorageStorageBlob @Props

    $keys = Invoke-AzureNativeStorageListStorageAccountKeys -accountName $storageAccount.reference("name") -resourceGroupName $resourceGroup.reference("name")

    New-PulumiOutput -Name test -Value $storageAccount.reference("primaryEndpoints.web")
    New-PulumiOutput -Name primarykey -Value $keys.reference("keys[0].value")
}
