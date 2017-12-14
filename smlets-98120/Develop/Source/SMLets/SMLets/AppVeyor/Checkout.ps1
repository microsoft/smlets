set-location C:\projects\smlets

$tf = 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\TF.exe'

$LatestChangeset = & $tf changeset /latest /noprompt /collection:https://tfs.codeplex.com:443/tfs/TFS07  "/login:snd\AdamDriscoll_cp,$env:CodePlexPassword"

$Lines = $LatestChangeset.Split([Environment]::NewLine, [Int]::MaxValue, 'RemoveEmptyEntries')
$Changeset = $Lines[0].Split(":")[1].trim()
$Author = $Lines[1].Split(":")[1].trim()
#$Date = [DateTime](Lines[2].Split(":")[1].trim())
$Comment = ''
$Items = ''
$line = 0
while($Lines[$line].trim() -ne 'Comment:')
{
    $line++
}

$line++

while($Lines[$line].trim() -ne 'Items:')
{
    if (-not [String]::IsNullorEmpty($lines[$line]))
    {
        $Comment += $Lines[$line].trim() + [Environment]::NewLine
    }
    
    $line++
}

$line++

while($Line -lt $lines.Length)
{
    $Items += $Lines[$Line].Trim() + [Environment]::NewLine
    $line++
}

Update-AppveyorBuild -Message $Comment -CommitterName $Author -CommitId $Changeset 

& $tf workspace /delete "APPVEYOR-VM;AdamDriscoll_CP" /collection:https://tfs.codeplex.com:443/tfs/TFS07  "/login:snd\AdamDriscoll_cp,$env:CodePlexPassword"
& $tf workspace /new /collection:https://tfs.codeplex.com:443/tfs/TFS07 "/login:snd\AdamDriscoll_CP,$env:CodePlexPassword" /noprompt
& $tf get /all "/login:snd\AdamDriscoll_cp,$env:CodePlexPassword"