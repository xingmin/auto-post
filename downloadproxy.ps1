
function Get-ProxyList(){
	[CmdletBinding()]
	param(
		[parameter(Mandatory=$true,
        HelpMessage="输入待分析的网址")]
		[string] $url
	)
	$webclient = New-Object Net.WebClient
	#$webClient.Headers.Add("Content-Type", "application/x-www-form-urlencoded");#采取POST方式必须加的header，如果改为GET方式的话就去掉这句话即可
	$webClient.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36");
	$responseData = $webClient.DownloadData($url);#得到返回字符流
	$srcString = [Text.Encoding]::UTF8.GetString($responseData);#解码
	#Write-Host $srcString;
	$htmlDoc= New-Object -com "HTMLFILE"
	$page = $srcString;
	$htmlDoc.write($page);
	$iplisttbl = $htmlDoc.GetElementById("ip_list");
	$iplistarr = New-Object 'System.Collections.Generic.List[System.Collections.Hashtable]'
	foreach($tr in $iplisttbl.firstChild.childNodes){
		$i=0
		$ip=@{}
		foreach($td in $tr.childNodes){
			$val = $td.innerText;
			if($val) { $val = $val.Trim()}
			if($i -gt 0){
				if($i -eq 1){
					$ip["ip"]=$val;
				}
				if($i -eq 2){
					$ip["port"]=$val;
				}
				if($i -eq 3){
					$ip["location"]=$val;
				}
				if($i -eq 4){
					$ip["attr"]=$val;
				}
				if($i -eq 5){
					$ip["type"]=$val;
				}
			}
			$i=[int]$i+1;
		}
	#	("{0}|{1}|{2}|{3}|{4}" -f $ip["ip"],$ip["port"],$ip["location"],$ip["attr"],$ip["type"] ) | Out-File -Append -FilePath $saveto
		$iplistarr.Add($ip)
	}
	Write-Output $iplistarr
}
function Get-AllProxyList2File(){
	[CmdletBinding()]
	param(
		[parameter(Mandatory=$true,
        HelpMessage="输入待分析的网址")]
		[string] $url,
		[parameter(Mandatory=$true,
        HelpMessage="保存文件")]
		[string] $listfile
		)
	for($i=1;1;$i++){
		$urii = ("{0}{1}" -f $url,$i)
		Write-Verbose "Geting Proxy List From $urii"
		$proxylist = Get-ProxyList -url $urii
		if($proxylist.GetType().Name -ne "Object[]" ){
			break;
		}
		$proxylist |%{("{0}|{1}|{2}|{3}|{4}" -f $_["ip"],$_["port"],$_["location"],$_["attr"],$_["type"] )} | Out-File -Append -FilePath $listfile
	}
}
function Get-FilteredProxyList(){
	[CmdletBinding()]
	param(
		[parameter(Mandatory=$true,
        HelpMessage="代理文本文件")]
		[string] $listfile
		)
	$iplistarr = New-Object 'System.Collections.Generic.List[System.Collections.Hashtable]'
	Get-Content -Path $listfile | Where-Object {
		($_ -match "山东") -and ($_ -match "HTTP(?![Ss])")
	}|%{
		$vals = $_.split("|")
		$ip = @{}
		$ip["ip"]=$vals[0];
		$ip["port"]=$vals[1];
		$ip["location"]=$vals[2];
		$ip["attr"]=$vals[3];
		$ip["type"]=$vals[4];
		$iplistarr.Add($ip)
	}
	Write-Output $iplistarr
}

if($myinvocation.CommandOrigin -eq [System.Management.Automation.CommandOrigin]::Runspace){
	$url = "http://www.xici.net.co/nt/";#地址	
#	Write-Host $url
#	Get-ProxyList -url $url
#	Get-AllProxyList2File -url $url -listfile "d:\test.txt"
	Get-FilteredProxyList "d:\test.txt"
	##
}

