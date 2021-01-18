#Log dosyasini olusturuyorum.
New-Item -Path "C:\temp\" -Name "CPU_log.txt" -ItemType "file"

#Jobumun triggerini olusturuyorum.
#Tarihini siz istediginiz bir zamana ayarlayin.
$tetik = New-JobTrigger -At "19/01/2021 00:14:50" -RepetitionInterval (New-TimeSpan -Minutes 1) -RepeatIndefinitely $true

#Jobumu olusturuyorum.
Register-ScheduledJob -Name 'cpuLogJob' -Trigger $tetik -ScriptBlock {
  $cekirdek_sayisi = (Get-WMIObject Win32_ComputerSystem).NumberOfLogicalProcessors

  #Kodun calistigi siradaki zamani aliyorum.
  $tarih_saat = Get-Date -Format "MM/dd/yyyy HH:mm"
  $tarih_saat

  #Get-Counter '\Process(*)\% Processor Time'
  #Processlerin hepsinin yuzdelik kullanimini aliyor.
  #Ama ornegin 4 cekirdek varsa 400 uzerinden alir.
  #Bu yuzden cekirdek sayisina boluyorum.
  #-ErrorAction SilentlyContinue
  #Get-Counter calismaya devam ederken processler calismaya devam ediyor.
  #Veya kapanabiliyorlar...
  #Bu bir hataya neden oluyor.
  #Arastirdigima gore hatalar guvenli bir bicimde bu komutla skiplenebilirler.
  $kirktan_cok_processler = (Get-Counter '\Process(*)\% Processor Time' -ErrorAction SilentlyContinue).
  CounterSamples | Where-Object {
  ($_.InstanceName -ne '_total') -and
  ($_.InstanceName -ne 'idle') -and
  ((($_.CookedValue)/$cekirdek_sayisi) -gt 0.1)}
  #total ve idle'yi cikartip aliyorum.

  #Processlerin listesini alip, tarih ve ismiyle dosyaya yazdiriyorum.
  $process_listesi = $kirktan_cok_processler.InstanceName
  foreach ($i in $process_listesi){
    $i = $tarih_saat + ' ' + $i
    $i | Add-Content C:\temp\CPU_log.txt
  }

  #Dosya satir sayisini aliyorum
  $dosya_satir_sayisi = (Get-Content C:\temp\CPU_log.txt | Measure-Object –Line).Lines

  #Eger dosyadaki satir sayisi 5000'i astiysa, eski yarisini siliyorum.
  if ($dosya_satir_sayisi -ge 5000){
    $satir_array = Get-Content C:\temp\CPU_log.txt
    $eski_yarisi_atilmis_log = $satir_array[-2500..-1]
    $eski_yarisi_atilmis_log > C:\temp\CPU_log.txt
  }
} #Burada job'un scripti bitiyor.

#Jobu kaldirmak icin bu komut kullaniliyor.
#Unregister-ScheduledJob cpuLogJob