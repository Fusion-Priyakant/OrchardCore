$base = ".\src\OrchardCore.Cms.Web\bin\Debug\net8.0\"

cd $base\Instrumented

$task = $args[0]

if ($task -ceq "check")
{
    echo "Check"
    echo "-----"
    .\Check.cmd
}
elseif ($task -ceq "deploy")
{
    echo "Deploy"
    echo "------"
    .\Deploy.cmd
}
elseif ($task -ceq "rollback")
{
    echo "Rollback"
    echo "--------"
    .\Rollback.cmd
}
