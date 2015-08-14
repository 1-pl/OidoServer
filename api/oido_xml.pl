#
sub parse_xml
{
	$xmlText = shift;
	require XML::DOM ; #qw(:strict);
	my $parser = new XML::DOM::Parser(ProtocolEncoding=>'UTF-8');
	my $request = $parser->parse($xmlText);
	
	return $request;
}
sub create_xml()
{	
	
	require XML::DOM ; #qw(:strict);
	
	
	$doc = new XML::DOM::Document;
	
	#my $xs = XML::Simple->new();

	# my $ref = $xs->XMLin( );
	
	##my $xml = $xs->XMLout($href,(RootName=>'Oido', XMLDecl=>1));
	$root = $doc->getDocumentElement();
	
	$doc->appendChild($doc->createElement('Oido'));
	
	return  $doc ;
}

1;
