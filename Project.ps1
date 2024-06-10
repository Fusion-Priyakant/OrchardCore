$base = ".\src\OrchardCore.Cms.Web\bin\Debug\net8.0"
$root = ".\..\..\..\..\.."

$task = $args[0]

cd $base
powershell $root\FusionLiteProject.ps1 $task
