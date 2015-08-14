#!C:/Perl64/bin/perl.exe

#use IPC::System::Simple qw(system capture);

$var = @ARGV[0];

(my $root,$rest) = split /\// , $var,2;
#$root="oido";
#$rest="xml/categories/category1";

if($root eq "oido")
{
	require ".\\oido.pl";
}
elsif($root eq "drain")
{
	require ".\\drain.pl";
}
else
{
	print "Status: 403 Not Found\r\n";
	print "Content-Type: text/html\r\n\r\n";

	print "<h1>404 Service $root not present on this server</h1>";
	exit 0;
	#restX() ;
}
	$ret = header();
	if($ret == 0)
	{
		$ret = message();
	}
	else
	{
		$ret = 0;
	}
#	$ret = system($^X ,".\\oido.pl",$rest);
	exit $ret;


sub restX()
{

print "Test<$root>\n";
print "use DBI <$rest>\n";
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

}
