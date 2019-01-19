Param(

    [bool]$noDockerBuild = $False,
    [bool]$pushDockerFile = $False,
    [string]$IMAGE_TAG = "dev",
    [string]$baseContainerTag = "latest",
    [string]$dockerFileLocation = "./"
)

# creates dockerfile for multiple plattforms as needed.
# pass "-noDockerBuild 1" as first argument to only generate dockerfiles without building them

# enter desired plattforms here (following the docker notation, e.g. arm32v7
$targetArch = @("amd64", "arm32v7")

############################################################################
# Normally you should nothing change below this line

Push-Location $dockerFileLocation

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8' # fix encoding issues when using wrong charset causing docker to read trash

Write-Output "Start generation of docker files for archs $targetArch"

foreach($baseArchDocker in $targetArch)
{
        $filePath = Resolve-Path -Path "Dockerfile.$baseArchDocker"

        copy Dockerfile.cross $filePath

        (Get-Content $filePath) -replace "__BASE-CONTAINER-TAG__", "$baseArchDocker-$baseContainerTag" | Out-File $filePath

        
        # fix line-endings to use unix style
        $content = [IO.File]::ReadAllText($filePath) -replace "`r`n","`n"
        [IO.File]::WriteAllText($filePath, $content)
}


if ( $noDockerBuild ) 
{
	Write-Output "-noDockerBuild 1 was specified, skipping container generation"
    Pop-Location
	exit 0
}


foreach ($baseArchDocker in $targetArch)
{
	Write-Output "`n`n`n###########################################################"
	Write-Output "Start docker build for $baseArchDocker `n`n`n"

	# $IMAGE_TAG var is injected into the build so the tag is correct.

    $gitRev = git rev-parse --short HEAD
    $date = date -u +"%Y-%m-%dT%H:%M:%SZ"

	docker build --build-arg VCS_REF=$gitRev --build-arg BUILD_DATE=$date -t cometvisu/cometvisu:$baseArchDocker-$IMAGE_TAG -f Dockerfile.$baseArchDocker .
    
    if ($pushDockerFile) 
    {
	    docker push cometvisu/cometvisuabstractbase:$baseArchDocker-$IMAGE_TAG
    }
}

Pop-Location