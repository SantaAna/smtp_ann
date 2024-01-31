defmodule SmtpAnn.SpfParser do
  import NimbleParsec
  import SmtpAnn.SpfParser.Helpers 
  
  defparsec :ip4_entry, ip4_entry() 
  defparsec :a_entry, a_entry()
  defparsec :mx_entry, mx_entry()
  defparsec :domain_name, domain_name()
  defparsec :include_entry, include_entry()
  defparsec :spf, spf()
end
