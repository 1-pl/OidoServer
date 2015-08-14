#

sub prepareDB()
{
	my $host = shift;
	my $dbname = shift;
	my $user = shift;
	my $passwd = shift;
	#my ($param1,$rest) = $rest =~ m/([^\/]+)\/(.*)$/;
	use DBI;
	$dbh = DBI->connect("DBI:mysql:$dbname", "$user", "$passwd"
	           ) || return undef ;
	
	return $dbh;
}
1;