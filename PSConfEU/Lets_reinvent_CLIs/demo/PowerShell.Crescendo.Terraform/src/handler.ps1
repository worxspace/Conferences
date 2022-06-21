function ParseTerraformApply {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        $input
    )
    process {
        $input | ConvertFrom-Json #| select -ExpandProperty "@message"
    }
}
