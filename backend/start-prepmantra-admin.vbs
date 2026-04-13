' ══════════════════════════════════════════════════════
'  PrepMantra Admin Panel — Silent Launcher
'  Double-click this .vbs to start with NO terminal popup
' ══════════════════════════════════════════════════════

Dim oShell, oFSO
Set oShell = CreateObject("WScript.Shell")
Set oFSO   = CreateObject("Scripting.FileSystemObject")

Const BACKEND_DIR = "D:\Projects\PrepMantra\backend"
Const ADMIN_URL   = "http://localhost:5500/admin.html"
Const CHROME_64   = "C:\Program Files\Google\Chrome\Application\chrome.exe"
Const CHROME_32   = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"

' Use ExpandEnvironmentStrings — works in all VBScript versions
Dim CHROME_USER
CHROME_USER = oShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Google\Chrome\Application\chrome.exe"

' ── Check if port 5500 already in use ────────────────────────────
Dim bRunning : bRunning = False
Dim oExec, sLine
Set oExec = oShell.Exec("cmd /c netstat -an")
Do While Not oExec.StdOut.AtEndOfStream
    sLine = oExec.StdOut.ReadLine()
    If InStr(sLine, ":5500") > 0 Then
        bRunning = True
        Exit Do
    End If
Loop

' ── Start Python server if not running ───────────────────────────
If Not bRunning Then
    oShell.Run "cmd /c python -m http.server 5500 --directory """ & BACKEND_DIR & """", 0, False
    WScript.Sleep 2000
End If

' ── Open Chrome (try 3 paths, fallback to default browser) ───────
Dim sChrome : sChrome = ""
If oFSO.FileExists(CHROME_64)   Then sChrome = CHROME_64
If sChrome = "" And oFSO.FileExists(CHROME_32)   Then sChrome = CHROME_32
If sChrome = "" And oFSO.FileExists(CHROME_USER) Then sChrome = CHROME_USER

If sChrome <> "" Then
    oShell.Run """" & sChrome & """ --new-window """ & ADMIN_URL & """", 1, False
Else
    oShell.Run "explorer """ & ADMIN_URL & """", 1, False
End If
