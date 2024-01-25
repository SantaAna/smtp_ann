# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SmtpAnn.Repo.insert!(%SmtpAnn.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

~w(combined.mail.abusix.zone truncate.gbudb.net rbl.metunet.com bl.mailspike.org dnsbl.sorbs.net sbl.spamhaus.org dnsbl.justspam.org psbl.surriel.com db.wpbl.info bl.spamcop.net spam.spamrats.com b.barracudacentral.org bl.0spam.org black.dnsbl.brukalai.lt rbl.metunet.com  bip.virusfree.cz)
|> IO.inspect(label: "server to create")
|> Enum.each(&SmtpAnn.DnsblServers.create_dnsbl_server(%{dns_name: &1}))
