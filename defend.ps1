#defend.ps1

# Function to Enable DNS over HTTPS (DoH)
function Enable-DoH {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableAutoDoH" -Value 2

    Write-Host "DNS over HTTPS has been enabled."
}

# Function to Setup Quad9 DNS over HTTPS
function Setup-Quad9-DoH {
    $quadDoHAddress = "https://dns.quad9.net/dns-query"
    $interfaceAlias = "Ethernet 3"
    
    # Configure DNS over HTTPS using Set-DnsClientServerAddress
    Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses $quadDoHAddress

    Write-Host "Quad9 DNS over HTTPS has been configured."
}

# Function to Configure Firewall
function Configure-Firewall {
    $ruleName = "BlockHTTP"
    $port = 80
    $protocol = "TCP"
    
    $rule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    
    if ($null -eq $rule) {
        New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -Action Block -Protocol $protocol -LocalPort $port
        Write-Host "Outbound HTTP traffic (TCP port $port) is now blocked."
    } else {
        Write-Host "The firewall rule to block outbound HTTP traffic is already in place."
    }
}

# Function to Perform Comprehensive Security Test
function Comprehensive-Test {
    TestDNSBlock
    Test-HTTPBlocking
    Write-Host "Comprehensive security test completed."
}

# Function to test HTTP blocking
function Test-HTTPBlocking {
    $websiteToTest = "https://www.example.com"
    
    try {
        $response = Invoke-WebRequest -Uri $websiteToTest -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "Website is accessible. HTTP blocking might not be in place."
        } else {
            Write-Host "Website response: $($response.StatusDescription). HTTP blocking might be in place."
        }
    } catch {
        Write-Host "An error occurred while testing: $($error[0].Exception.Message)"
    }
}

# Function to test DNS block status
function TestDNSBlock {
    $originalDNS = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -eq "Ethernet 3"}).ServerAddresses
    Write-Host "Original DNS server: $originalDNS"

    $malwareIP = Resolve-DnsName -Name "malware.testcategory.com" | Select-Object -ExpandProperty IPAddress
    if ($malwareIP -ne "0.0.0.0") {
        Write-Host "Host is not using DNS filtering."
    }
    else {
        Write-Host "Host is using DNS filtering."
    }
}

# Check for the command-line argument and execute the appropriate function
$command = $args[0]

switch ($command) {
    "DoH-enable" {
        Enable-DoH
    }
    "setup-quad-doh" {
        Setup-Quad9-DoH
    }
    "configure-firewall" {
        Configure-Firewall
    }
    "comprehensive-test" {
        Comprehensive-Test
    }
    default {
        Write-Host "Usage: .\Defend.ps1 <command>"
        Write-Host "Available commands: DoH-enable, setup-quad-doh, configure-firewall, comprehensive-test"
    }
}
