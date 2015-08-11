#!C:/Perl64/bin/perl.exe

	print "Content-type: text/plain; charset=utf-8\n\n";

print "Test\n";
print "<@ARGV[0]>";
print "use DBI\n";
use DBI;
print "connect\n";
$dbh = DBI->connect('DBI:mysql:oido', 'root', ''
	           ) || print "Could not connect";
print "Select\n";
$out = $dbh->prepare('SELECT CategoryName,oid FROM category ');	 

print "Execute\n";
$sth = $out->execute() ;
print "Out:$sth\n";
while(@result = $out->fetchrow())
{
  
  print "Cat:@result[0] \t";
  print "OID:@result[1]\n";
}

$dbh->disconnect();
