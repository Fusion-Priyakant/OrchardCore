$FusionLiteProjectProperties = "FusionLiteProject.properties"
$Properties = ConvertFrom-StringData (Get-Content $FusionLiteProjectProperties -raw)

$FusionLiteProject = $Properties["FusionLiteProject"]

$FusionLiteServerHost = $Properties["FusionLiteServerHost"]
$FusionLiteServerPort = [int] $Properties["FusionLiteServerPort"]

$FusionLiteServerUser = $Properties["FusionLiteServerUser"]
$FusionLiteServerKeyFile = $Properties["FusionLiteServerKeyFile"]

$ApplicationFile = $Properties["ApplicationFile"]
$ApplicationInclude = $Properties["ApplicationInclude"]
$ApplicationExclude = $Properties["ApplicationExclude"]

$InstrumentedFile = $Properties["InstrumentedFile"]
$InstrumentedFolder = $Properties["InstrumentedFolder"]

$ExecutionFile = Split-Path $MyInvocation.MyCommand.Path -Leaf
$ExecutionPath = Split-Path $MyInvocation.MyCommand.Path -Parent

$LibraryFile = "Renci.SshNet.dll"
$LibraryPath = $ExecutionPath + "\" + $LibraryFile

$target = $args[0]

if ($target -ceq "project")
{
echo "-------"
echo "Project"
echo "-------"

Add-Type -Path $LibraryPath

$keyfile = New-Object Renci.SshNet.PrivateKeyFile($FusionLiteServerKeyFile)
$sshclient = New-Object Renci.SshNet.SshClient($FusionLiteServerHost, $FusionLiteServerPort, $FusionLiteServerUser, $keyfile)
$sshclient.Connect()

if ($sshclient.IsConnected)
{
    $cmdtext = "Project" + ":" + $FusionLiteProject
    "Cmd" + " : " + $cmdtext
    $command = $sshclient.RunCommand($cmdtext)
    $command.Result

    $sshclient.Disconnect()
}
}
elseif ($target -ceq "structure")
{
echo "---------"
echo "Structure"
echo "---------"

Add-Type -Path $LibraryPath

$keyfile = New-Object Renci.SshNet.PrivateKeyFile($FusionLiteServerKeyFile)
$sshclient = New-Object Renci.SshNet.SshClient($FusionLiteServerHost, $FusionLiteServerPort, $FusionLiteServerUser, $keyfile)
$sshclient.Connect()

if ($sshclient.IsConnected)
{
    $cmdtext = "Structure" + ":" + $FusionLiteProject
    "Cmd" + " : " + $cmdtext
    $command = $sshclient.RunCommand($cmdtext)
    $command.Result

    $sshclient.Disconnect()
}
}
elseif ($target -ceq "initialize")
{
echo "------------"
echo "Initializing"
echo "------------"

Add-Type -Path $LibraryPath

$keyfile = New-Object Renci.SshNet.PrivateKeyFile($FusionLiteServerKeyFile)
$sshclient = New-Object Renci.SshNet.SshClient($FusionLiteServerHost, $FusionLiteServerPort, $FusionLiteServerUser, $keyfile)
$sshclient.Connect()

if ($sshclient.IsConnected)
{
    $cmdtext = "Initialize" + ":" + $FusionLiteProject
    "Cmd" + " : " + $cmdtext
    $command = $sshclient.RunCommand($cmdtext)
    $command.Result

    $sshclient.Disconnect()
}
}
elseif ($target -ceq "instrument")
{
echo "----------"
echo "Initiating"
echo "----------"

if ($ApplicationInclude -or $ApplicationExclude)
{
    # Remove Old Application Zip
    if (Test-Path $ApplicationFile) { Remove-Item $ApplicationFile -ErrorAction Stop }

    $Files = @(Get-ChildItem -Path . -Recurse -File)
    $FilePaths = $Files | ForEach-Object -Process { Write-Output -InputObject $_.FullName }

    # Create New Application Zip
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    "Zip" + " : " + $ApplicationFile
    $zip = [System.IO.Compression.ZipFile]::Open($ApplicationFile, [System.IO.Compression.ZipArchiveMode]::Create)

    # Add Application Zip Entries
    foreach ($filepath in $FilePaths)
    {
        $fileentry = $(Resolve-Path -Path $filepath -Relative) -replace '\.\\',''
        if (!$fileentry.StartsWith($InstrumentedFolder + "\") -and !$fileentry.Equals($FusionLiteProjectProperties))
        {
            if (!$ApplicationInclude -or $fileentry -match $ApplicationInclude)
            {
                if (!$ApplicationExclude -or $fileentry -notmatch $ApplicationExclude)
                {
                    "Zip" + " : " + $fileentry
                    $zipentry = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $filepath, $fileentry)
                }
            }
        }
    }

    # Close Application Zip
    $zip.Dispose()
}

Add-Type -Path $LibraryPath

$keyfile = New-Object Renci.SshNet.PrivateKeyFile($FusionLiteServerKeyFile)
$sshclient = New-Object Renci.SshNet.SshClient($FusionLiteServerHost, $FusionLiteServerPort, $FusionLiteServerUser, $keyfile)
$sshclient.Connect()

if ($sshclient.IsConnected)
{
    $cmdtext = "Clean" + ":" + $FusionLiteProject
    "Cmd" + " : " + $cmdtext
    $command = $sshclient.RunCommand($cmdtext)
    $command.Result

    echo ""

    echo "------------"
    echo "Transmitting"
    echo "------------"

    $sftp = New-Object Renci.SshNet.SftpClient($sshclient.ConnectionInfo)
    $sftp.Connect()

    if ($sftp.IsConnected)
    {
        "Tx" + " : " + $ApplicationFile + " : " + (Get-Item $ApplicationFile).length + " " + "bytes"
        $sftp.ChangeDirectory($FusionLiteProject)
        $sftp.ChangeDirectory("Input")
        $ApplicationFileStream = [System.IO.File]::OpenRead($ApplicationFile)
        $sftp.UploadFile($ApplicationFileStream, $ApplicationFile)
        $ApplicationFileStream.Close()
        $sftp.Disconnect()
    }

    echo ""

    echo "-------------"
    echo "Preprocessing"
    echo "-------------"

    $cmdtext = "PreProcess" + ":" + $FusionLiteProject
    "Cmd" + " : " + $cmdtext
    $command = $sshclient.RunCommand($cmdtext)
    $command.Result

    echo ""

    echo "-------------"
    echo "Instrumenting"
    echo "-------------"

    $cmdtext = "Instrument" + ":" + $FusionLiteProject
    "Cmd" + " : " + $cmdtext
    $command = $sshclient.RunCommand($cmdtext)
    $command.Result

    echo ""

    echo "--------------"
    echo "Postprocessing"
    echo "--------------"

    $cmdtext = "PostProcess" + ":" + $FusionLiteProject
    "Cmd" + " : " + $cmdtext
    $command = $sshclient.RunCommand($cmdtext)
    $command.Result

    echo ""

    echo "---------"
    echo "Receiving"
    echo "---------"

    # Remove Old Instrumented Folder
    if (Test-Path $InstrumentedFolder) { Remove-Item $InstrumentedFolder -Recurse -ErrorAction Stop }

    # Create New Instrumented Folder
    New-Item -Path $InstrumentedFolder -ItemType Directory -ErrorAction Stop | Out-Null

    $sftp = New-Object Renci.SshNet.SftpClient($sshclient.ConnectionInfo)
    $sftp.Connect()

    if ($sftp.IsConnected)
    {
        $sftp.ChangeDirectory($FusionLiteProject)
        $sftp.ChangeDirectory("Output")
        $InstrumentedFileStream = [System.IO.File]::OpenWrite($InstrumentedFolder + "\" + $InstrumentedFile)
        $sftp.DownloadFile($InstrumentedFile, $InstrumentedFileStream)
        $InstrumentedFileStream.Close()
        $sftp.Disconnect()
        "Rx" + " : " + $InstrumentedFile + " : " + (Get-Item ($InstrumentedFolder + "\" + $InstrumentedFile)).length + " " + "bytes"
    }

    $sshclient.Disconnect()

    echo ""

    echo "----------"
    echo "Finalizing"
    echo "----------"

    if ($InstrumentedFolder -eq "Instrumented" -and $InstrumentedFile -eq "Instrumented.zip")
    {
        # Extract Instrumented Zip
        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        "Unzip" + " : " + $InstrumentedFile
        [System.IO.Compression.ZipFile]::ExtractToDirectory($InstrumentedFolder + "\" + $InstrumentedFile, $InstrumentedFolder)

        # Remove Instrumented Zip
        Remove-Item ($InstrumentedFolder + "\" + $InstrumentedFile) -ErrorAction Stop
    }
}
}
elseif ($target -ceq "decompile")
{
echo "---------"
echo "Decompile"
echo "---------"

Add-Type -Path $LibraryPath

$keyfile = New-Object Renci.SshNet.PrivateKeyFile($FusionLiteServerKeyFile)
$sshclient = New-Object Renci.SshNet.SshClient($FusionLiteServerHost, $FusionLiteServerPort, $FusionLiteServerUser, $keyfile)
$sshclient.Connect()

if ($sshclient.IsConnected)
{
    $cmdtext = "Decompile" + ":" + $FusionLiteProject
    "Cmd" + " : " + $cmdtext
    $command = $sshclient.RunCommand($cmdtext)
    $command.Result

    $sshclient.Disconnect()
}
}
