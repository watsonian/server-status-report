# Script for gathering system status information from a linux server. This has
# only been tested on Debian linux systems. It outputs HTML text that is meant
# to be piped into the mail command for delivery:
# 
# ruby status.rb | mail -a "Content-type: text/html;" -s "Status Report: $HOSTNAME" "some@address.com"
# 
# In Debian, you just need the mailx package installed for the above to work
# along with Ruby (of course).

require 'erb'

timestamp = Time.now.strftime("%B %d, %Y @ %I:%M%p %Z")
hostname = `hostname`
load_avg = `uptime | awk -F'average(s)?:' '{print $2}'`

# Memory usage
totalmem = `free -m | grep Mem: | awk '{print $2}'`.to_i
usedmem = `free -m | grep Mem: | awk '{print $3}'`.to_i
cachedmem = `free -m | grep Mem: | awk '{print $7}'`.to_i
memused = `free -m | grep buffers/cache: | awk '{print $3}'`.to_i
actual_usedmem = usedmem - cachedmem
actual_freemem = totalmem - actual_usedmem

php_procs = `ps -ef | grep -v grep | grep -c php`
httpd_procs = `ps -ef|grep -v grep|grep -c httpd`
tcp_connections = `netstat -nat | grep tcp | awk '{ print $5}' | cut -d: -f1 | sed -e '/^$/d' | uniq | wc -l`

open_tcp_connections = `netstat -atun | grep tcp | awk '{print $5}' | cut -d: -f1 | sed -e '/^$/d' | sort | uniq -c | sort -n`
top_memory_procs = `ps aux --sort=-rss | head -11`.chomp.strip
top_cpu_procs = `ps aux --sort=-pcpu | grep -v grep | grep -E "(^([^ ]*?)[ ]*[0-9]*[ ]*(([0-9]{1,2}\.[1-9])|([1-9]{1,2}\.[0-9])))|USER" | head -11`.chomp.strip
netstat = `netstat -a --tcp | sort`.chomp.strip
top_snapshot = `COLUMNS=230 && top -c -b -n1`.chomp.strip

# Determine graph color
memused_percent = ((actual_usedmem.to_f / totalmem.to_f) * 100).round

if memused_percent < 33
  graph_color = "ACE97C"
elsif memused_percent > 33 && memused_percent < 66
  graph_color = "E9C981"
else
  graph_color = "E9B19A"
end

template = %q{
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">

<html lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>System Status</title>
</head>
<body style="margin:0px;padding:0px;font-family: 'Helvetica';">
  <div id="header" style="background:#4888C9;border:2px solid #7EAEC9;border-left:none;border-right:none;text-shadow: rgba(0, 0, 0, 0.296875) -1px -1px 1px;">
    <table>
      <td>
        <p style="margin:0px;padding:10px;color:#FFF;font-weight:bold;font-size:2.5em;">System Status: <strong><%= hostname %></strong></p>
      </td>
      <td>
        <p style="color:#FFF;font-weight:normal;font-size:1em;"><%= timestamp %></p>
      </td>
    </table>
  </div>
  <div id="body" style="">
    <p style="margin:0px;padding:5px;font-size:1em;"><strong>Load averages:</strong> <%= load_avg %></p>
    <h3 style="margin:0px;margin-left:5px;margin-right:5px;border-bottom:1px solid #DDD;padding-left:5px;padding-bottom:3px;padding-top:10px;color:#EA7F00;font-weight:bold;font-size:1em;">Memory Usage</h3>
    <table style="">
      <tr>
        <th style="text-align:right;">Used:</th>
        <td style="vertical-align:middle;">
          <div class="progress-container" style="border: 1px solid #ccc;width: 300px;margin-top:2px;margin-right:5px;margin-bottom:2px;margin-left:0px;padding:1px;float: left;background: white;">
              <div style="background-color:#<%= graph_color %>;height:20px;width:<%= memused_percent %>%;"></div>
          </div>
        </td>
        <td>
          <strong>Used:</strong> <%= actual_usedmem %>MB <strong>&bull; Total:</strong> <%= totalmem %>MB <strong>&bull; Free:</strong> <%= actual_freemem %>MB
        </td>
      </tr>
    </table>
    <h3 style="margin:0px;margin-left:5px;margin-right:5px;border-bottom:1px solid #DDD;padding-left:5px;padding-bottom:3px;padding-top:10px;color:#EA7F00;font-weight:bold;font-size:1em;">Process / Connection Counts</h3>
    <table style="">
      <tr>
        <th style="text-align:right;">connections:</th>
        <td><%= tcp_connections %></td>
      </tr>
      <tr>
        <th style="text-align:right;">php:</th>
        <td><%= php_procs %></td>
      </tr>
      <tr>
        <th style="text-align:right;">httpd:</th>
        <td><%= httpd_procs %></td>
      </tr>
    </table>
    <h3 style="margin:0px;margin-left:5px;margin-right:5px;border-bottom:1px solid #DDD;padding-left:5px;padding-bottom:3px;padding-top:10px;color:#EA7F00;font-weight:bold;font-size:1em;">Open Connections</h3>
    <pre style="background:#000;color:#FFF;padding:10px;margin:5px;overflow:scroll;">
<%= open_tcp_connections %></pre>
    <h3 style="margin:0px;margin-left:5px;margin-right:5px;border-bottom:1px solid #DDD;padding-left:5px;padding-bottom:3px;padding-top:10px;color:#EA7F00;font-weight:bold;font-size:1em;">Top 10 Memory Processes</h3>
    <pre style="background:#000;color:#FFF;padding:10px;margin:5px;overflow:scroll;">
<%= top_memory_procs %>
</pre>
    <h3 style="margin:0px;margin-left:5px;margin-right:5px;border-bottom:1px solid #DDD;padding-left:5px;padding-bottom:3px;padding-top:10px;color:#EA7F00;font-weight:bold;font-size:1em;">Top 10 CPU Processes</h3>
    <pre style="background:#000;color:#FFF;padding:10px;margin:5px;overflow:scroll;">
<%= top_cpu_procs %></pre>
    <h3 style="margin:0px;margin-left:5px;margin-right:5px;border-bottom:1px solid #DDD;padding-left:5px;padding-bottom:3px;padding-top:10px;color:#EA7F00;font-weight:bold;font-size:1em;">Netstat</h3>
    <pre style="background:#000;color:#FFF;padding:10px;margin:5px;overflow:scroll;">
<%= netstat %></pre>
    <h3 style="margin:0px;margin-left:5px;margin-right:5px;border-bottom:1px solid #DDD;padding-left:5px;padding-bottom:3px;padding-top:10px;color:#EA7F00;font-weight:bold;font-size:1em;">System Snapshot from top</h3>
    <pre style="background:#000;color:#FFF;padding:10px;margin:5px;overflow:scroll;">
<%= top_snapshot %></pre>
  </div>
</body>
</html>
}

puts ERB.new(template).result