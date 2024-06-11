$base = ".\src\OrchardCore.Cms.Web"

cd $base

$task = $args[0]

if ($task -ceq "original")
{
    echo "Running Original"
    echo "----------------"
    dotnet run --no-build --framework net8.0
}
elseif ($task -ceq "instrumented")
{
    echo "Running Instrumented"
    echo "--------------------"
    dotnet run --no-build --framework net8.0 --additional-deps Instrumented.deps.json
}
