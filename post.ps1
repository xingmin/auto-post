pushd  (Split-Path -Parent $MyInvocation.MyCommand.Definition)
. ./downloadproxy.ps1
function Do-Post(){
	[CmdletBinding()]
	param(
		[parameter(Mandatory=$true,
        HelpMessage="代理URI")]
		[string] $proxyAddressAndPort
		)
	$regex  = [regex]"(?<apprisetotal>\d+)"
	$postString = "Q1=1&Q2=1&Q3=1&Q4=1&Q5=1&HospitalId=5753";
	#这里即为传递的参数，可以用工具抓包分析，也可以自己分析，主要是form里面每一个name都要加进来

	$postData = [Text.Encoding]::UTF8.GetBytes($postString);#编码，尤其是汉字，事先要看下抓取网页的编码方式

	$url = "http://www.fxyy.org/appraise/hos/5753";#地址

	$webclient = New-Object Net.WebClient
#	$proxyAddressAndPort="http://222.132.11.6:8080"; 
	$proxyUserName = "";
	$proxyPassword = "";
	if ($proxyAddressAndPort -ne ""){
	    $cred = New-Object Net.NetworkCredential($proxyUserName, $proxyPassword); 
		$p = New-Object Net.WebProxy($proxyAddressAndPort, $true, $null, [Net.ICredentials]$cred);  
#		[Net.WebRequest]::DefaultWebProxy=$p;
		$webclient.Proxy = $p;
	}
	#$webclient.Credentials = CredentialCache.DefaultCredentials;

	$webClient.Headers.Add("Content-Type", "application/x-www-form-urlencoded");#采取POST方式必须加的header，如果改为GET方式的话就去掉这句话即可
	$webClient.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36");
	try{
	$responseData = $webClient.UploadData($url, "POST", $postData);#得到返回字符流
	
	$srcString = [Text.Encoding]::UTF8.GetString($responseData);#解码
	$htmlDoc= New-Object -com "HTMLFILE"
	$page = $srcString;
	$htmlDoc.write($page);
	$h2s = $htmlDoc.getElementsByTagName("h2");
	$appriseresult=1;
	$total = -1;
	foreach($h in $h2s){
		$retval = $h.innerText;
		if ( $retval.trim() -match "提交成功"){
			$appriseresult=0;
		}
		$ms = $regex.match($retval);
		if($ms.Success){
			$total =  $ms.Groups["apprisetotal"].Value;
		}
	}			
	Write-Output @{"appriseresult"=$appriseresult;
	"apprisetotal"=$total}
	
	}catch {
		Write-Error $Error[0]
		Write-Output  @{"appriseresult"=1;
	"apprisetotal"=-1}
		
	}finally{
		$webclient.Dispose()
		return
	}

}
function Auto-Post(){
	[CmdletBinding()]
	param(
		[parameter(Mandatory=$true,
        HelpMessage="代理URI的保存文件")]
		[string] $listfile,
		[parameter(Mandatory=$true,
        HelpMessage="自动提交的间隔")]
		[int] $interval=5,	
		[parameter(Mandatory=$true,
        HelpMessage="自动提交次数")]
		[int] $count=1
		)
	$proxylist = Get-FilteredProxyList -listfile $listfile 
	if($proxylist -eq $null){
		Write-Output ("{0}投票失败[无代理]。" -f (Get-Date -Format "[yyyy-MM-dd hh:mm:ss]"))
		return
	}
	for($i=0;$i -lt $count; $i++){
		if($proxylist.GetType().Name -ne "Object[]" ){
			$proxy = $proxylist;
		}else{
			$idx = get-random -Minimum 0 -Maximum ($proxylist.Count-1)
			$proxy = $proxylist[$idx];
		}
		$uri = "http://{0}:{1}" -f $proxy["ip"],$proxy["port"];
		Write-Host ("Using Proxy post:{0}" -f $uri);
		$res = Do-Post -proxyAddressAndPort $uri;
		if ($res["appriseresult"] -eq 0){
			Write-Host ("{0}成功投票：{1}" -f (Get-Date -Format "[yyyy-MM-dd HH:mm:ss]"),$res["apprisetotal"])
		}else{
			Write-Host ("{0}投票失败。" -f (Get-Date -Format "[yyyy-MM-dd hh:mm:ss]"))
		}
		Start-Sleep -Seconds $interval
	}
# 
	 
}
if($myinvocation.CommandOrigin -eq [System.Management.Automation.CommandOrigin]::Runspace){
 
	#[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
	#$interval = [Microsoft.VisualBasic.Interaction]::InputBox("请输入自动投票间隔：", "自动投票间隔", 5) 
	Auto-Post -listfile ".\test.proxy" -interval 5 -count 2
 
}
