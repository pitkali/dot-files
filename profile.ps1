if ($host.Name -eq 'ConsoleHost')
{
    Import-Module PSReadLine
}
Import-Module -Name Terminal-Icons
Import-Module posh-git
$env:POSH_GIT_ENABLED = $true

oh-my-posh --init --shell pwsh --config ~/.my-config/kali.omp.json | Invoke-Expression

