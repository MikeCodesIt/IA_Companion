Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$welcome = "IA Companion Logfile. `nIndividual Contributors: Mike Gronau, Gino Pepenella"

Write-Output $welcome | Out-File "logfile.txt"

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "File Picker GUI"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Add a title label at the top of the form
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Select a File"
$titleLabel.Location = New-Object System.Drawing.Point(20, 10)
$titleLabel.Size = New-Object System.Drawing.Size(360, 20)
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$titleLabel.TextAlign = 'MiddleCenter'
$form.Controls.Add($titleLabel)

# Add a label for file description above the browse button
$fileLabel = New-Object System.Windows.Forms.Label
$fileLabel.Text = "File containing IP Addresses"
$fileLabel.Location = New-Object System.Drawing.Point(20, 50)
$fileLabel.Size = New-Object System.Drawing.Size(360, 20)
$fileLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Regular)
$fileLabel.TextAlign = 'MiddleLeft'
$form.Controls.Add($fileLabel)

# Create the TextBox to display the file path
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(20, 80)
$textBox.Size = New-Object System.Drawing.Size(250, 20)
$textBox.ReadOnly = $true
$form.Controls.Add($textBox)

# Create the Browse button
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Location = New-Object System.Drawing.Point(280, 80)
$browseButton.Size = New-Object System.Drawing.Size(80, 20)
$browseButton.Text = "Browse"
$form.Controls.Add($browseButton)

# Create the Ping button
$pingButton = New-Object System.Windows.Forms.Button
$pingButton.Location = New-Object System.Drawing.Point(20, 120)
$pingButton.Size = New-Object System.Drawing.Size(340, 30)
$pingButton.Text = "Ping IP Addresses"
$pingButton.Enabled = $false
$form.Controls.Add($pingButton)

# Create a label to display the result
$resultLabel = New-Object System.Windows.Forms.Label
$resultLabel.Location = New-Object System.Drawing.Point(20, 160)
$resultLabel.Size = New-Object System.Drawing.Size(360, 80)
$resultLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Regular)
$form.Controls.Add($resultLabel)

# Create and configure the OpenFileDialog
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog
$fileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
$fileDialog.Title = "Select a File"

# Add the Click event for the Browse button
$browseButton.Add_Click({
    if ($fileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBox.Text = $fileDialog.FileName
        $pingButton.Enabled = $true
    }
})

# Add the Click event for the Ping button
$pingButton.Add_Click({
    # Read the file and get IP addresses
    $ipAddresses = Get-Content -Path $textBox.Text

    # Variables to hold the results
    $ipsUp = @()
    $ipsDown = @()
    $windowsHosts = @()
    $linuxHosts = @()


    # Ping each IP address
    foreach ($ip in $ipAddresses) {
        $pingResult = Test-Connection -ComputerName $ip -Count 1 -Quiet
        $resultLabel.Text = "Sending ping to... $ip"
        if ($pingResult) {
            $ipsUp += $ip
            $ipsUpList = $ipsUpList = @()
            if (Test-NetConnection -ComputerName $ip -Port "22" -InformationLevel Quiet) {
                $linuxHosts += $ip
                Write-Output ("$ip   -- STATUS: UP -- Determined to be Linux") | Out-File "logfile.txt" -Append
                continue
            }
            elseif (Test-NetConnection -ComputerName $ip -Port "3389" -InformationLevel Quiet) {
                $windowsHosts += $ip
                Write-Output ("$ip   -- STATUS: UP -- Determined to be Windows") | Out-File "logfile.txt" -Append  
            }


        } else {
            $ipsDown += $ip
            $resultLabel.Text = "$ip  -- STATUS: DOWN"
            Write-Output $resultLabel.Text | Out-File "logfile.txt" -Append
        }
    }

    # Update the result label
    $resultLabel.Text = "IPs Up: $($ipsUp.Count)`nIPs Down: $($ipsDown.Count) `nSee logfile in local directory for details"
})

# Display the form
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()