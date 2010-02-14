# Overview

Oftentimes you might be interested in the status of your server without having to actually sit there staring at a terminal window. Wouldn't it be nice if you could run a script to email you information about the state of your server? Well, that's exactly what this script does. It outputs HTML 4.01 Strict compliant content containing information on your server including:

* load average
* memory usage
* open network connections
* top 10 memory processes
* top 10 CPU processes
* netstat output
* top snapshot of all running processes

This script was primarily written for and tested on DreamHost Private Servers.

# Installation

To install this script, the first thing you want to do is download a copy of the script to use. To do that, SSH to your PS under the user you want to run the script as and run this command:

 curl -s -o status.rb https://gist.github.com/raw/b8d670dfb8bf97a3be9f/7fbcc76a118ac1f24ce144048d816b6b699911b6/status.rb

That will save the script as a file named __status.rb__. The script itself is written in Ruby to take advantage of the [ERB templating system](http://ruby-doc.org/stdlib/libdoc/erb/rdoc/classes/ERB.html) to produce the HTML content.

Once you've downloaded the script successfully, you need to make sure that the __mailx__ package is installed on your PS. To find out, run this command:

    dpkg -l | grep mailx

If you see output like this:

    ii  mailx                                       8.1.2-0.20050715cvs-1                A simple mail user agent

then that means it's installed. If instead you see output like this:

    rc  mailx                                       8.1.2-0.20050715cvs-1                A simple mail user agent

then that means you need to install it. To do so, login with an admin with sudo privileges and run the following command:

    sudo apt-get install mailx

Now you're ready to create a cron job to send yourself your status report. The command you want to run is as follows:

    /usr/bin/ruby /path/to/script/status.rb | /usr/bin/mail -a "Content-type: text/html;" -s "Status Report: $HOSTNAME" "some@address.com"

You can change the subject to whatever you want and just replace __some@address.com__ with the address you want the email sent to. If you want to CC the email to more email addresses you can use the __-c__ flag and pass it a comma separated list of email addresses. Running it once per hour is probably not a bad idea, but you can run it as frequently or infrequently as you like!

# Conclusion

If you set everything up properly, then you should start getting emails that look roughly like this:

http://wiki.dreamhost.com/images/5/58/Server_status_script_preview.png

Keep in mind that this script will likely be updated as time progresses. So, if this stops working for you, be sure to check back to see if the script has been updated.