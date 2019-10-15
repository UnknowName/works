$ZIP_TOOL = "WinRAR.exe"
$LOG_DISK = "E:\"
$_TOAY = $(Get-Date)
$_LAST_MONTH = $_TOAY.AddMonths(-1)
$MONTH = $_LAST_MONTH.ToString("yyyyMM")


# Get Zip Tool's EXE file
function Get-Zip {
    $ZIP_EXE = ""
    $disks = [Environment]::GetLogicalDrives()
    foreach($disk in $disks) {
        cd $disk
        $file = $(gci . -Recurse -name -include $ZIP_TOOL)
        if ($file -ne $null) {
           $ZIP_EXE = "$disk$file"
           break
        }
    }
    if ($ZIP_EXE -eq "") {
        echo "Not Fond Zip Tools,Exit"
        exit 9
    } else {
        return "$ZIP_EXE"
    }
}


# Get log file path
function Get-Log-Paths {
    $paths = @()
    $logsFile = $(Get-ChildItem -Path $LOG_DISK -Recurse -include "*$MONTH*.txt")
    foreach($log in $logsFile) {
        $path = $(Split-Path -Path $log)
        echo "$(Split-Path -Path $log -leaf)" >> $path\log.lst
        if(!$paths.Contains($path)) {
            $paths += $path
        }
    }
    return $paths
}


# Zip the log files
function Zip-Log {
    echo "In function Zip-Log"
    $zip_tool = Get-Zip
    # $zip_tool = "C:\Program Files\WinRAR\WinRAR.exe"
    $logPaths = Get-Log-Paths
    foreach($logPath in $logPaths) {
        cd  $logPath
        cmd /c $zip_tool  a -df  "$MONTH.zip"  "@log.lst"
        # init the log.list null
        echo "" > $logPath\log.lst
    }
} 


Zip-Log