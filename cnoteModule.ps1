<#
function to store notes in 'Cornell' format
more info:  https://lsc.cornell.edu/how-to-study/taking-notes/cornell-note-taking-system/
#>
function New-CNote {
    param (
        [Parameter (Mandatory = $false)] [Switch]$review
    )

    Clear-Host  
    #datafile location
    $notesFunctionDataFile = "$($env:USERPROFILE)\Documents\CNotes\notesFunctionData.csv"
    try {Get-Item $notesFunctionDataFile -ErrorAction Stop | Out-Null} catch {New-Item $notesFunctionDataFile -Value "" -Force | Out-Null}

    #helper functions
    function Get-NoteData { #display 'type' of data
        param ($source,$type)
        Write-Host "Current $($type.ToUpper())(s):"  -ForegroundColor Cyan
        $source | Where-Object {$_.noteType -eq $type} | ForEach-Object {Write-Host $_.noteEntry}      
    }
    #end of helper functions

    #'review' logic
    if ($review) {
        try {$notesFunctionData = Import-Csv $notesFunctionDataFile} 
        catch {Write-Host "No existing data to be reviewed."; Write-Host "Expected data file: $($notesFunctionDataFile)";break}
        $notesFunctionData | Where-Object {$_.noteType -eq "title"} | Select-Object noteEntry,noteDatetime,noteType
        foreach ($item in $notesFunctionData) {
            if ($item.noteType -eq "title") {
                $indexNumber = $notesFunctionData.indexOf($item)
                Write-Host "Date: $($item.noteDatetime) - Index: $indexNumber - Title: $($item.noteEntry)"
            }
        }
        $selectedIndex = Read-Host "What Title 'Index' # would you like to review?"
        Clear-Host
        $selectedGuid = $notesFunctionData["$selectedIndex"].noteID
        $selectedData = $notesFunctionData | Where-Object {$_.noteID -eq $selectedGuid}
        Get-NoteData -source $selectedData -type "title"
        Write-Host "==================================" -ForegroundColor Yellow
        Get-NoteData -source $selectedData -type "cue"
        Write-Host "==================================" -ForegroundColor Yellow
        Get-NoteData -source $selectedData -type "note"
        Write-Host "==================================" -ForegroundColor Yellow
        Get-NoteData -source $selectedData -type "summary"
        $export = Read-Host "Would you like to export to HTML? Y/N"
        #export html
        if ($export -eq "y") {

$html = @"
<!doctype html>
<html lang="en" data-theme="light">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://unpkg.com/@picocss/pico@latest/css/pico.min.css">
    <title>Note</title>
  </head>
  <body>
     <main class="container">

        <h4>Title:  <mark>$($selectedData | Where-Object {$_.noteType -eq "title"} | ForEach-Object {Write-Output $_.noteEntry})</mark></h4>
        <h6>Date Taken:  $($selectedData | Where-Object {$_.noteType -eq "title"} | ForEach-Object {Write-Output ($_.noteDatetime | Get-Date -Format "dddd MM/dd/yyyy HH:mm K")})</h6>
        <section id="notedata">
        <div class="grid">
            <div><b>Cues:</b><br>$($selectedData | Where-Object {$_.noteType -eq "cue"} | ForEach-Object {Write-Output "$($_.noteEntry) <br>"})</div>
            <div><b>Notes:</b><br>$($selectedData | Where-Object {$_.noteType -eq "note"} | ForEach-Object {Write-Output "$($_.noteEntry) <br>"})</div>
        </div>
        </section>

        <h4>Summary:  <mark>$($selectedData | Where-Object {$_.noteType -eq "summary"} | ForEach-Object {Write-Output $_.noteEntry})</mark></h4>

        <h6><small>
        NoteID: $($selectedData | Where-Object {$_.noteType -eq "title"} | ForEach-Object {Write-Output $_.noteID})
        <br>
        Taken By: $($selectedData | Where-Object {$_.noteType -eq "title"} | ForEach-Object {Write-Output $_.noteBy})
        </small></h6>
        
        </main>
    </body>
</html>
"@
        $exportFileNameID = ($selectedData | Where-Object {$_.noteType -eq "title"} | select -ExpandProperty noteID).Substring(0,8)
        $exportFileNameDate = ($selectedData | Where-Object {$_.noteType -eq "title"} | select -ExpandProperty noteTimeStamp) | Get-Date -Format "yyyyMMdd"
        $exportFullFileName = "$($env:USERPROFILE)\Documents\CNotes\$($exportFileNameDate)-$($exportFileNameID).html"
        Write-Host "Exporting CNotes entry to file: $($exportFullFileName)"
        New-Item $exportFullFileName -Value $html -force
        Invoke-Expression $exportFullFileName
        } #end of export html logic
        break
    } #end of review logic
    
    #prep for incoming data
    $noteGuid = New-Guid
    $data = @()
    #friendly date and time, such as for Excel
    function Get-NoteDateTime {Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt'}
    #comprehensive timestamp with UTC
    function Get-NoteTimestamp {Get-Date -Format 'o'}

    #display current time(s)
    $msg = "current datetime: $(Get-NoteDateTime)"
    $border = "=" * $($msg.Length)
    Write-Host $border -ForegroundColor Green
    Write-Host $msg -ForegroundColor Green
    $msg = "current timestamp: $(Get-NoteTimestamp)"
    Write-Host $msg -ForegroundColor Green
    $border = "=" * $($msg.Length)
    Write-Host $border -ForegroundColor Green
    Write-Host "Enter a TITLE to proceed:" -ForegroundColor Green
    ""
    Write-Host "Title: " -NoNewline
    $entry = Read-Host # "Title"
    $data += [pscustomobject]@{noteType = "title"; noteEntry = $entry; noteTimestamp = Get-NoteTimestamp; noteDatetime = Get-NoteDateTime}

    #main logic
    do {
        #prompt msg
        Clear-Host
        Get-NoteData -source $data -type "title"
        Get-NoteData -source $data -type "cue"
        Get-NoteData -source $data -type "note"
        Write-Host "Action: (C)ue, (N)ote, (T)itle, (D)elete, or e(X)it"
        $nextAction = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Select-Object -ExpandProperty Character
        $possibleActions = @("c","n","x","t","d")
        #error msg
        if ($possibleActions -notcontains $nextAction) {Write-Host "Invalid action - Try again." -ForegroundColor Yellow}
        #cue input
        if ($nextAction -eq "c") {
            [string]$noteInput = Read-Host "Enter text for cue"
            $dataObject = [pscustomobject]@{noteType = "cue"; noteEntry = $noteInput; noteTimestamp = Get-NoteTimestamp; noteDatetime = Get-NoteDateTime}
            $data += $dataObject
        }
        #note input
        if ($nextAction -eq "n") {
            [string]$noteInput = Read-Host "Enter text for note"
            $dataObject = [pscustomobject]@{noteType = "note"; noteEntry = $noteInput; noteTimestamp = Get-NoteTimestamp; noteDatetime = Get-NoteDateTime}
            $data += $dataObject
        }
        #change title
        if ($nextAction -eq "t") {
            [string]$noteInput = Read-Host "Enter new text for title" -
            $data[0] = [pscustomobject]@{noteType = "title"; noteEntry = $noteInput; noteTimestamp = Get-NoteTimestamp; noteDatetime = Get-NoteDateTime}
        }
        #delete entry
        if ($nextAction -eq "d") {
            foreach ($item in $data) {
                if ($item.noteType -ne "title") {
                    $indexNumber = $data.indexOf($item)
                    Write-Host "Index: $indexNumber - Type: $($item.noteType) - Entry: $($item.noteEntry)"
                }
            }
            $selectedIndex = Read-Host "What Entry 'Index' # would you like to delete?"
            if ($selectedIndex) {$data = $data | Where-Object {$data.indexOf($_) -ne $selectedIndex}}
        }
        #end of main logic
    } while ($nextAction -ne "x")

    #recap
    Clear-Host
    Get-NoteData -source $data -type "title"
    Get-NoteData -source $data -type "cue"
    Get-NoteData -source $data -type "note"

    #summarize
    $entry = Read-Host "Summary"
    $data += [pscustomobject]@{noteType = "summary"; noteEntry = $entry; noteTimestamp = Get-NoteTimestamp; noteDatetime = Get-NoteDateTime}

    #tag with noteID and username
    $data | Add-Member -MemberType NoteProperty -Name noteID -Value $noteGuid
    $data | Add-Member -MemberType NoteProperty -Name noteBy -Value $($env:UserName)

    #save note
    Write-Host "Updating CNotes file [$($notesFunctionDataFile)] with latest data."
    try {$data | Export-Csv $notesFunctionDataFile -Append -Force} catch {Write-Error "Error writing to $($notesFunctionDataFile)"}

} #end of full function
