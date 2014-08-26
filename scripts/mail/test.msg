ehlo
mail from: user2@red.iplanet.com RET=HDRS ENVID=AAAAAAA
rcpt to: user32 notify=SUCCESS ORCPT=rfc822;user32@red.iplanet.com
rcpt to: user4 notify=FAILURE ORCPT=rfc822;user4
rcpt to: user5 notify=NEVER
data
To: user32, user4, user5
From: user2
Subject: HELLO TEST MAIL
A
.
quit
