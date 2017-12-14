# smlets

This project provides cmdlets for System Center Service Manager 2010/2010 SP1/2012/2012 SP1/2012 R2 which can be used to automate common tasks.


# Getting started!
1. Download the .msi and run it 
2. If you had PS running when you installed the .msi, restart PS 
3. Then run "PS> Import-Module SMLets"

Your now ready to use the module.

To learn what's in the module, run the following command: 
PS>Get-SCSMCommand

To learn which parameters a cmdlets makes use of, run the following command:
PS>Get-Help Get-SCSMClass
Note: Replace Get-SCSMClass with the cmdlet you want to get parameters for.

To run commands remotely, make use of the -ComputerName parameter.
