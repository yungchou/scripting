# Collect the .blg files and convert them to .csv files. 
$sourceBlgFolder = 'E:\_azure.MS.training\_css perf training'
$blgFiles = Get-ChildItem -Recurse -Path $sourceBlgFolder -Filter "*.blg"

foreach ($file in $blgFiles) {
    relog -f csv $file.FullName -o $file.FullName.Replace('.blg','.csv')
}
