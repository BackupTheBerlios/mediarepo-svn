email_text = <<"END_EMAIL"
To: "Me" <#{to_addr}>
From: #{from_addr}
Subject: That thar logfile turned up somethin'

Hi, #{to_addr},

Here's the email about the logfile thing.
END_EMAIL

# now the sendmail part...

IO.popen("/usr/sbin/sendmail #{to_addr}", "w") do |sendmail|
  sendmail.print email_text
end
