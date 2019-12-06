<#
.SYNOPSIS
Check-ComputerReplication takes one or more domaincontrollers, and one computer name. It will then query the specified domain controller(s) if the computer object exist in the specifed OU.
.DESCRIPTION
Check-ComputerReplication runs a test-connect before querying the dc, then it uses get-adcomputer to check if the object exist in specified OU and return an object with information to the pipeline.
.PARAMETER DomainController
The Domain Controller(s) to query.
.PARAMETER ComputerName
The computer object to query the domain controllers with.
.PARAMETER FQDN
The fully qualified domain name for the domain where the domain controllers reside.
.PARAMETER OU
The OU the query the domain controllers for the computer object.
.EXAMPLE
Check-ComputerReplication -ComputerName LABPC001 -DomainController 'LABDC001','LABDC002'
.NOTES
By Einar Kristiansen
#>

function Get-ComputerReplication {
    [CmdletBinding()]
    #^ Optional ..Binding(SupportShouldProcess=$True,ConfirmImpact='Low')
    param (
    [Parameter(Mandatory=$True,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True)]
    [Alias('CN','MachineName','HostName','Name')]
    [string]$DomainController,

    [Parameter(Mandatory=$True,
    ValueFromPipelineByPropertyName=$True)]
    [string[]]$ComputerName,

    [Parameter(Mandatory=$False)]
    [string]$FQDN = 'corp.com',

    [Parameter(Mandatory=$False)]
    [string]$OU = 'OU=Computers,DC=corp,DC=com'
    )

BEGIN {
    # Intentionaly left empty.
    # Provides optional one-time pre-processing for the function.
    # Setup tasks such as opening database connections, setting up log files, or initializing arrays.
}

PROCESS {
    foreach($server in $DomainController){
        $TestCon = Test-Connection -ComputerName "$server.$FQDN" -BufferSize 4 -Count 2 -Quiet

        if($TestCon){
            Write-Verbose "$server : Searching for $ComputerName"
            
            # Check if we can find the computer object on the specified server
            $GetComputer = Get-ADComputer -SearchBase $OU -Filter "Name -like '$ComputerName'" -Server "$server.$FQDN" -Properties Modified
            
            # Output an object to pipeline with result
            if($GetComputer){
                $Properties = @{Server=$Server
                                Computer=$ComputerName
                                Connection='Successful'
                                ExistsInOU='Yes'
                                Modified=$GetComputer.Modified
                        }
                # Output object
                New-Object -TypeName psobject -Property $Properties
            }else{
                $Properties = @{Server=$Server
                        Computer=$ComputerName
                        Connection='Successful'
                        ExistsInOU='No'
                        Modified=''
                }
                # Output object
                New-Object -TypeName psobject -Property $Properties
            } #Else GetComp
        }else{
            $Properties = @{Server=$Server
                    Computer=$ComputerName
                    Connection='Failed'
                    ExistsInOU=''
                    Modified=''
            }
            # Output object
            New-Object -TypeName psobject -Property $Properties            
        } #Else TestCon
    } #Foreach
} #PROCESS


END {
    # Intentionaly left empty.
    # This block is used to provide one-time post-processing for the function.
}

} #Function