puts "Enter the number os nodes:"
set tnn [gets stdin]

#===================================
#     Simulation parameters setup
#===================================
set val(chan)   Channel/WirelessChannel    ;# channel type
set val(prop)   Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)  Phy/WirelessPhy            ;# network interface type
set val(mac)    Mac/802_11                 ;# MAC type
set val(ifq)    Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)     LL                         ;# link layer type
set val(ant)    Antenna/OmniAntenna        ;# antenna model
set val(ifqlen) 100                        ;# max packet in ifq
set val(nn)     $tnn                       ;# number of mobilenodes
set val(adhocRouting)     AODV             ;# routing protocol
set val(x)      1500                       ;# X dimension of topography
set val(y)      1500                       ;# Y dimension of topography
set val(stop)   10.0                       ;# time of simulation end

#===================================
#        Initialization        
#===================================
#Create a ns simulator
set ns [new Simulator]

#Setup topography object
set topo       [new Topography]
$topo load_flatgrid $val(x) $val(y)
create-god $val(nn)

#Open the NS trace file
set tracefile [open out.tr w]
$ns trace-all $tracefile

#Open the NAM trace file
set namfile [open out.nam w]
$ns namtrace-all $namfile
$ns namtrace-all-wireless $namfile $val(x) $val(y)
set chan [new $val(chan)];#Create wireless channel

set f0 [open out02.tr w]
set f1 [open lost02.tr w]
set f2 [open delay02.tr w]

Mac/802_11 set cdma_code_bw_start 0;
Mac/802_11 set cdma_code_bw_stop 63;
Mac/802_11 set cdma_code_init_start 64;
Mac/802_11 set cdma_code_init_stop 127;
Mac/802_11 set cdma_code_cquich_start 128;
Mac/802_11 set cdma_code_cquich_stop 195;
Mac/802_11 set cdma_code_handover_start 196;
Mac/802_11 set cdma_code_handover_start 255;

#===================================
#     Mobile node parameter setup
#===================================
$ns node-config -adhocRouting  AODV \
                -llType        $val(ll) \
                -macType       $val(mac) \
                -ifqType       $val(ifq) \
                -ifqLen        $val(ifqlen) \
                -antType       $val(ant) \
                -propType      $val(prop) \
                -phyType       $val(netif) \
                -energymodel   EnergyModel\
                -initialenergy 100\
                -rxPower       0.3\
                -txPower       0.6\
                -channel       $chan \
                -topoInstance  $topo \
                -agentTrace    ON \
                -routerTrace   ON \
                -macTrace      ON \
                -movementTrace ON

#===================================
#        Nodes Definition        
#===================================
#Create n nodes
for {set i 0} {$i < $val(nn)} {incr i} {
set n($i) [$ns node]
$n($i) set X_ [expr rand()*500]
$n($i) set Y_ [expr rand()*500]
$n($i) set Z_ 0.0
}
for {set i 0} {$i < $val(nn)} {incr i} {
$ns initial_node_pos $n($i) 50
set xx [expr rand()*1500]
set yy [expr rand()*1500]
$ns at 0.1 "$n($i) setdest $xx $yy 5"
}


#===================================
#        Agents Definition        
#===================================

puts "Enter Source"
set source [gets stdin]

puts "Enter Destination"
set dest [gets stdin]

#Setup a UDP connection
set udp0 [new Agent/UDP]
$ns attach-agent $n($source) $udp0
set sink [new Agent/LossMonitor]
$ns attach-agent $n($dest) $sink
$ns connect $udp0 $sink
$udp0 set packetSize_ 1500


#===================================
#        Applications Definition        
#===================================
#Setup a CBR Application over UDP connection
set cbr0 [new Application/Traffic/CBR]
$cbr0 attach-agent $udp0
$cbr0 set packetSize_ 1000
$cbr0 set interval_ 0.1
$cbr0 set maxpkts 10000
$ns at 1.0 "$cbr0 start"

set holdtime 0
set holdseq 0
set holdrate 0

proc record {} {
	global sink f0 f1 f2 holdtime holdseq holdrate ns
	set time 0.9;
	set now [$ns now]
	set bw0 [$sink set bytes_]
	set bw1 [$sink set nlost_]
	set bw2 [$sink set lastPktTime_]
	set bw3 [$sink set npkts_]
	puts $f0 "$now [expr (($bw0+$holdtime)/(2*$time*1000000))]"
	puts $f1 "$now [expr ($bw1/$time)]"
	if {$bw3>$holdseq} {
		puts $f2 "$now [expr ($bw2-$holdtime)/($bw3-$holdseq)]"
	} else {
		puts $f2 "$now [expr $bw3-$holdseq]"
	}
	$sink set bytes_ 0
	$sink set nlost_ 0
	set holdtime $bw2
	set holdseq $bw3
	set holdrates $bw0
	$ns at [expr $now+$time] "record"
}

$ns at 0 "record"
$ns at 0.5 "$n($source) add-mark m blue square"
$ns at 0.5 "$n($dest) add-mark m magenta square"
$ns at 0.5 "$n($source) label Sender"
$ns at 0.5 "$n($dest) label Reciever"


#===================================
#        Termination        
#===================================
#Define a 'finish' procedure
proc finish {} {
    global ns tracefile namfile
    $ns flush-trace
    close $tracefile
    close $namfile
    exec nam out.nam &
    exec xgraph out02.tr -t Throughput &
    exec xgraph lost02.tr -t PacketLoss &
    exec xgraph delay02.tr -t Delay &
    exit 0
}
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at $val(stop) "$n($i) reset"
}
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "finish"
$ns at $val(stop) "puts \"done\" ; $ns halt"
$ns run