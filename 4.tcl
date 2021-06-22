if {$argc != 1} {
	error "Commad: <Name>.tcl <Number_of_Nodes>"
	exit 0
}
set val(chan)   Channel/WirelessChannel    ;
set val(prop)   Propagation/TwoRayGround   ;
set val(netif)  Phy/WirelessPhy            ;
set val(mac)    Mac/802_11                 ;
set val(ifq)    Queue/DropTail/PriQueue    ;
set val(ll)     LL                         ;
set val(ant)    Antenna/OmniAntenna        ;
set val(ifqlen) 50                         ;
set val(nn)     [lindex $argv 0]           ;
set val(rp)     AODV                      ;
set val(x)      750                      ;
set val(y)      750                      ;
set val(stop)   100.0                         ;
set ns [new Simulator]
set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)
create-god $val(nn)
set tracefile [open out.tr w]
$ns trace-all $tracefile
set namfile [open out.nam w]
$ns namtrace-all $namfile
$ns namtrace-all-wireless $namfile $val(x) $val(y)
set chan [new $val(chan)];#Create wireless channel
$ns node-config -adhocRouting  $val(rp) \
                -llType        $val(ll) \
                -macType       $val(mac) \
                -ifqType       $val(ifq) \
                -ifqLen        $val(ifqlen) \
                -antType       $val(ant) \
                -propType      $val(prop) \
                -phyType       $val(netif) \
                -channel       $chan \
                -topoInstance  $topo \
                -agentTrace    ON \
                -routerTrace   ON \
                -macTrace      OFF \
                -movementTrace OFF
for {set i 0} {$i < $val(nn)} {incr i} {
	set n($i) [$ns node]
}
for {set i 0} {$i < $val(nn)} {incr i} {
	set XX [expr rand()*750]
	set YY [expr rand()*750]
	$n($i) set X_ $XX
	$n($i) set Y_ $YY 
}
$ns at 0.0 "destination"
for {set i 0} {$i < $val(nn)} {incr i} {
	$ns initial_node_pos $n($i) 50
}
proc destination {} {
	global ns val n
	set now [$ns now]
	set time 3.0
	for {set i 0} {$i < $val(nn)} {incr i} {
		set XX [expr rand()*750]
		set YY [expr rand()*750]
		$ns at [expr $now + $time] "$n($i) setdest $XX $YY 20.0"
	}
	$ns at [expr $now + $time] "destination"
}
set tcp0 [new Agent/TCP]
$ns attach-agent $n(0) $tcp0
set sink1 [new Agent/TCPSink]
$ns attach-agent $n(5) $sink1
$ns connect $tcp0 $sink1
$tcp0 set packetSize_ 1500
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0
$ns at 1.0 "$ftp0 start"
proc finish {} {
    global ns tracefile namfile
    $ns flush-trace
    close $tracefile
    close $namfile
    exec nam out.nam &
    exec awk -f 4.awk out.tr &
    exit 0
}
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at $val(stop) "$n($i) reset"
}
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "finish"
$ns at $val(stop) "puts \"done\" ; $ns halt"
$ns run
