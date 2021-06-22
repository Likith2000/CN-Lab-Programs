set val(stop) 10.0;
set ns [new Simulator]
set tracefile [open 5.tr w]
$ns trace-all $tracefile
set namfile [open 5.nam w]
$ns namtrace-all $namfile
set wf0 [open WinFile0 w]
set wf1 [open WinFile1 w]
proc PlotWindow {tcpSource file} {
global ns
set time 0.1
set now [$ns now]
set cwnd [$tcpSource set cwnd_]
puts $file "$now $cwnd"
$ns at [expr $now+$time] "PlotWindow $tcpSource $file"
}
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
$n0 label "Source0"
$n1 label "Source1"
$n2 label "R1"
$n3 label "R2"
$n4 label "Dest0"
$n5 label "Dest1"
$ns color 1 "red"
$ns color 2 "green"
$ns color 3 "blue"
$ns color 4  "orange"
set lan [$ns newLan "$n0 $n1 $n2" 0.5Mb 40ms LL Queue/DropTail MAC/802_3 Channel]
$ns duplex-link $n2 $n3 10Mb 100ms DropTail
$ns duplex-link-op $n2 $n3 queuePos 0.5
set lan [$ns newLan "$n3 $n4 $n5" 0.5Mb 40ms LL Queue/DropTail MAC/802_3 Channel]
set loss_module [new ErrorModel]
$loss_module ranvar [new RandomVariable/Uniform]
$loss_module drop-target [new Agent/Null]
$ns lossmodel $loss_module $n2 $n3
set tcp0 [new Agent/TCP]
$ns attach-agent $n0 $tcp0
set sink2 [new Agent/TCPSink]
$ns attach-agent $n4 $sink2
$ns connect $tcp0 $sink2
$tcp0 set packetSize_ 1500
set tcp1 [new Agent/TCP]
$ns attach-agent $n1 $tcp1
set sink3 [new Agent/TCPSink]
$ns attach-agent $n5 $sink3
$ns connect $tcp1 $sink3
$tcp1 set packetSize_ 1500
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0
$ns at 0.1 "$ftp0 start"
$ns at 9.8 "$ftp0 stop"
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ns at 1 "$ftp1 start"
$ns at 9.9 "$ftp1 stop"
$ns at 0.1 "PlotWindow $tcp0 $wf0"
$ns at 0.5 "PlotWindow $tcp1 $wf1"
$tcp0 set class_ 1
$tcp1 set class_ 2
proc finish {} {
  global ns tracefile namfile
  $ns flush-trace
  close $tracefile
  close $namfile
  exec nam 5.nam &
  exec xgraph WinFile0 WinFile1 &
  exit 0
}
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "finish"
$ns at $val(stop) "puts \"done\" ; $ns halt"
$ns run
