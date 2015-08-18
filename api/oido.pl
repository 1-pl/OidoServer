#!C:/Perl64/bin/perl.exe

sub logLine
{
	my $add = shift;
	$logData = "$logData" . "$add" ;
	return 0;
}
sub logAppend
{
	my $add = shift;
	my $child = $logNode->appendChild($doc->createElement('Item'));
	$child->setAttribute('time','X');
	$child->addText($add) ;
}
sub logAppend2
{
	my $add = shift;
	my $att = shift;
	my $child = $logNode->appendChild($doc->createElement('Item'));
	$child->setAttribute('time','X');
	if($att ne "")
	{
		$child->setAttribute('key',$att);
	}
	$child->addText($add) ;
}
sub header()
{
	$logData = "";
	$method = $ENV{ 'REQUEST_METHOD' } ;
	$acceptLang = $ENV{ 'HTTP_ACCEPT_LANGUAGE ' };
	$accept = $ENV{ 'HTTP_ACCEPT' } ;
	$pragma = $ENV{ 'HTTP_PRAGMA' } ;
	$logreq = $pragma =~ m/log-req/ ;
	# $rest =~   ;
	$old = $rest;
	($rest,$type) =  $rest =~ m/(.*)\/(.+)$/ ;
	# ($1,$2);
	
	if( $type eq "" and $rest eq "")
	{
		$type = $old ;

	}
	if($accept eq "application/xml")
	{
		$type = "xml";
		if($rest eq "")
		{
			$rest = $old ;
		}
	}
	if($type eq "xml" or $type eq "xmle")
	{
		print "Content-type: application/xml; charset=utf-8\n\n";
		#print "Content-type: text/plain; charset=utf-8\n\n";
		#print $logreq . ":" . 	$method . "\n"  ;
		foreach $keyd (keys %ENV)
		{
		#print "$keyd = $ENV{$keyd} \n";
		}
		#print $^X;
	}
	elsif($type eq "text")
	{
		print "Content-type: text/plain; charset=utf-8\n\n";
	}
	elsif($type eq "")
	{
	print "Status: 404 Not Found\r\n";
	print "Content-Type: text/html\r\n\r\n";

	print "<h1>404 you must specify a data format $old [ html | xml | text ] </h1>";
	}
	else
	{
	print "Status: 404 Not Found Format $accept $type\r\n";
	print "Content-Type: text/html\r\n\r\n";

	print "<h1>404 Data format $type not supported</h1>" .
				"<h3>Module oido supports [ html | xml | text ] </h3>";
	}
	return 0;
}

sub message()
{
	my ($query,$restrest) = split /\//,$rest;
	#my ($query,$rest) = $rest =~ m/([^\/]+)\/(.*)$/;
	@rest = split /\//,$restrest;
	if($type eq "xml")
	{
		require 'oido_xml.pl';
		$doc = create_xml();
		$root = $doc->getDocumentElement();
		$response = $doc->createElement('Response') ;
		$response->setAttribute("request",$method) ;
		$response->setAttribute("log-request","$logreq");
		$status = $doc->createElement('Status') ;
		$logNode = $doc->createElement('Log');
		logAppend $logData ;
		$input = "";
		$xml = "";
		do
		{
			$input = <stdin> ;
			$xml .= $input;
		}
		while($input);
		if($method eq "POST" or $method eq "PUT")
		{
			$request = parse_xml($xml);
			#print $xml;
			#print "POST $query $rest $old\n";
			#return ;
		}
		elsif($method eq "PUT")
		{
			print "PUT $query $rest $old\n";
			#print $xml;
			return ;
		}
		if($method eq "DELETE")
		{
			print "Delete $query $rest $old\n";
			return ;
		}
		foreach $key (%ENV)
		{
			logAppend2 $ENV{$key}, $key	;
		}
		if($query ne "path" and scalar @rest != 0 )
		{
			$status->setAttribute("status","0");
			
			$status->addText("$query Not implemented yet");
			
			$response->appendChild($status);
			
			$response->appendChild($logNode) ;
			$root->appendChild($response);
			print $doc->toString();
			return 0;
		}
		require 'oido_db.pl';
		#require 'example.pl';
		$dbh = prepareDB("localhost","oido_pl","root","");
	
		if($method eq "GET" and $query eq "path")
		{
			$status->setAttribute("status","0");
			
			$status->addText("OK");

			if($restrest ne "")
			{
				$oid = $restrest;
				$sql = "CALL listPath('" . $oid . "')" ;
				#$status->addText("$query <$sql><$str> Not fully implemented yet");
				$sth = $dbh->prepare($sql);
				$out = $sth->execute();
				if($sth->err)
				{
					$status->setAttribute("status","2");
					
					$status->addText("$query <$str->errmsg> ");
				}
				else
				{
					do
					{
						$result = $sth->fetchrow_arrayref();
						if($result)
						{
							if($str ne "")
							{
								$str .= '.';
							}
							$str .= $result->[1] ;
						}
					}
					while($result);
					$data = $doc->createElement("$query") ;
					$data->setAttribute("oid",$oid);
					$data->addText($str);
					$response->appendChild($data);
				}
			}
			$dbh->disconnect();
			
			$response->appendChild($status);
			
			$response->appendChild($logNode) ;
			$root->appendChild($response);
			print $doc->toString();
			return 0;
		}
		else
		{
			#print "query=$query \n";
		}
		if($method eq "POST")
		{
			$reqRoot = $request->getDocumentElement();
			$nodeWord = $reqRoot->getLastChild();
			my $name = $reqRoot->getTagName();
			if($query eq "")
			{
				$query = $name;
			}
			my $descPost = getNouns($query)->{ 'POST' } ;


			$querySelect = calcQuery($descPost,$query,$nodeWord);

			$response->setAttribute("query",$querySelect);
			my $last = 1;
			my $id = 1;

			#$dbh->do("SET \@id = ? ", undef, $id);
			#$dbh->do("SET \@last = ? ", undef, $last);

			$out = $dbh->prepare( $querySelect );

			
			$sth = $out->execute();

			if($out->err)
			{				
				if(not defined $data )
				{
					$data = $doc->createElement('Data') ;
				}
				$data->addText($out->errstr);
				
			}
			@result = $dbh->selectrow_array("SELECT \@id,\@last");
			$id = $result[0];
			$last = "$result[1]";
			$oid = $nodeWord->getAttribute("category") ;
			$oid .= '.' . $last ;
			$word = $nodeWord->getFirstChild()->getData();
			if(defined $data )
			{
				$root->appendChild($data);
			}
			$data = $doc->createElement("$query") ;
			$data->setAttribute("id",$id);
			$data->setAttribute("oid",$oid);
			$data->addText($word);
			#print "id=$result[0] last=$result[1]" . Dumper(@result) ;
			
			$alien = $request->getDocumentElement()->cloneNode(1);
			$alien->setOwnerDocument($doc);
			$root->appendChild($alien);
			$status->setAttribute("status","0");
			
			$status->addText("OK");
		}
		$desc = getNouns(' ')->{ 'GET' } ;
		if($query eq "")
		{
			queryNouns('query');
		}
		elsif($method eq "POST")
		{
		# all done
		}
		elsif( defined $desc->{'nouns'}->{ $query })
		{
			$data = $doc->createElement("$query") ;
			foreach $param (@rest)
			{
				$node = $doc->createElement("Param") ;
				
				$node->setAttribute("value","$param");
				$data->appendChild($node);
			}
			if(not defined $dbh)
			{
				$status->setAttribute("status","1");
				$status->addText("ERROR Connect Database");
			}
			elsif($method eq "GET")
			{
				$select = $desc->{'select'};
				$columns = $desc->{'columns'};
				$typeElement = $desc->{'nouns'}->{ $query }[0]{'type'};
				$querySelect = $select->{$query};
				$textColumn = $columns->{$query}{'@'};
				$allcolumns = $columns->{$query};
				logAppend $querySelect;
				logAppend $typeElement ;
				logAppend $allcolumns;
				logAppend $textColumn;
				logAppend Dumper($allcolumns);
				if(scalar @rest == 0)
				{
					$out = $dbh->prepare($querySelect);	 
					$sth = $out->execute() ;
					
					while(@result = $out->fetchrow())
					{
						$cat = $doc->createElement($typeElement) ;
						$cat->addText("@result[$textColumn]");
						
						foreach $col (keys %$allcolumns)
						{
							logAppend Dumper($col) ;
							if($col ne "@")
							{
								$cat->setAttribute("$col", "@result[$allcolumns->{$col}]");
							}
						}
						$data->appendChild($cat);
					}
					$status->setAttribute("status","0");
					
					$status->addText("OK");
				}
				else
				{
					$status->setAttribute("status","0");
					
					$status->addText("Not implemented yet");
				}
			}
			elsif($method eq "POST")
			{
				#$select = $desc->{'insert'};
				#$querySelect = $select->{$query};
				#$begin =~ s/\$\{word\}/$word/;
				#$response->setAttribute("word",$begin);
			}
		}
		else
		{
			$data = $doc->createElement("$query") ;
				$status->setAttribute("status","0");
				
				$status->addText("Not implemented yet");
		}
		$response->appendChild($data) ;
		$response->appendChild($status);
		
		if(defined $logreq and $logreq eq "1")
		{
			$response->appendChild($logNode) ;
		}
		$root->appendChild($response);
		print $doc->toString();
		if(defined $dbh)
		{
		$dbh->disconnect();
		}
	}
	elsif($type eq "xmle")
	{
		print "<root>";
		print "<elem query=\"" . $query . "\"/>" ;
		print "<rest>@rest</rest>";
		print "</root>";
	}
	elsif($type eq "text")
	{
	print "OIDO\n";
	print "Rest:$rest\n";

	print "Query=$query\n";
	print "type:$type\n";
	
	if($#rest)
	{		
		foreach $arg (@rest) 
		{
			print "$arg \n";
		}
	}
	}
	return 0;
}
sub calcQuery
{
	my $descPost = shift;
	my $query = shift;
	my $nodeWord = shift;
	my $select = $descPost->{'select'};
	my $attributes = $descPost->{'attributes'};
	my $querySelect = $select->{$query};
	my $queryAttr = $attributes->{$query};
	#print "@@ $querySelect @@\n";
	foreach my $attr ( keys %$queryAttr)
	{
		#print "@@@ $attr $queryAttr->{$attr}\n";
		if($attr eq '@')
		{
			$attrVal = $nodeWord->getFirstChild()->getData();
		}
		else
		{
			$attrVal =  $nodeWord->getAttribute($attr);
		}
		$begin = $querySelect =~ s/$queryAttr->{$attr}/\'$attrVal\'/ ;
	}
	#print "@@ $querySelect @@\n";
	#$oid = $nodeWord->getAttribute("category");
	#$begin = $querySelect =~ s/\$\{parent\}/\'$oid\'/ ;
	#$word = $nodeWord->getFirstChild()->getData();
	#$begin = $querySelect =~ s/\$\{word\}/\'$word\'/ ;
	return $querySelect;
}
sub getNouns()
{
	%nouns = ( 'Categories' => [ {  'type' => 'Category' , 'method' => 'standard' } ] ,
				'Words' => [  { 'type' => 'Word'  , 'method' => 'standard' } ],
				'Persons' => [  { 'type' => 'Person'  , 'method' => 'login' } ],
				'Databases' => [ { 'type' => 'Database' , 'method' => 'connect' } ] ,
				'Servers' => [ { 'type' => 'Server'  , 'method' => 'connect' } ],
				'Objects' => [  { 'type' => 'Object' , 'method' => 'standard' }  ] );
	%select = ( 'Categories' => 'CALL listAllCategories();' ,
					'Words' => 'CALL listAllWords();' ,
					'Persons' => 'SELECT CategoryName,oid FROM category' ,
					'Servers' => 'SELECT CategoryName,oid FROM category' ,
					'Databases' => 'SELECT CategoryName,oid FROM category' ,	
					'Objects' => 'CALL listAllObjects();' ) ;
	%columnsGet = (   'Categories' => { "@" => 1 , "oid" => 2 , "id" => 0 },
						'Words' => { "@" => 1 , "oid" => 2 , "id" => 0 },
						'Persons' => { "@" => 0 , "name" => 1 },
						'Servers' => { "@" => 0 , "URL" => 1 },
						'Objects' => { "@" => 1 , "id" => 0 , "oid" => 2 }
					);
	%attributesPost = (   'Categories' => { "@" => '\$\{word\}' , "category" => '\$\{parent\}'  },
						'Persons' => { "@" => 1 , "oid" => 2 , "id" => 0 },
						'Words' => { "@" => '\$\{word\}' , "category" => '\$\{parent\}'  },
						'Servers' => { "@" => 0 , "URL" => 1 },
						'Objects' => { "@" => 1 , "id" => 0 , "oid" => 2 } 
						);
	%paramSelect = ( 'Categories' => 'CALL storeCategory(${word},${parent},@last ,@id );' ,
					'Words' => 'CALL storeWord(${word},${parent},@last ,@id );' ,
					'Persons' => 'SELECT CategoryName,oid FROM category' ,
					'Servers' => 'SELECT CategoryName,oid FROM category' ,
					'Databases' => 'SELECT CategoryName,oid FROM category' ,	
					'Objects' => 'CALL listAllObjects();' ) ;


	my $refGet = { } ; 
	my $refPost = { } ; 
	my $refPut = { } ; 
	my $refDelete = { } ; 
	
	$refGet->{ 'nouns' } = \%nouns ;
	$refGet->{ 'select' } = \%select;
	$refGet->{ 'columns' } = \%columnsGet;
	$refPost->{ 'nouns' } = \%nouns;
	$refPost->{ 'select' } = \%paramSelect;
	$refPost->{ 'attributes' } = \%attributesPost;
				
	return { 'GET' => $refGet , 'POST' => $refPost } ;
}
sub queryNouns()
{
	use Data::Dumper;
	my $query = "Nouns";
	$refNouns = getNouns()->{ 'GET' } ;
	
	$ref = $refNouns->{'nouns'};
	$response->setAttribute("type",$query) ;
	$data = $doc->createElement($query) ;
	foreach $key (sort keys %$ref)
	{
		$cat = $doc->createElement('Noun') ;
		$cat->addText($key);
		
		foreach $attr (  @{%$ref{ $key }})
		{
			foreach $key2 ( sort keys %$attr)
			{
			#print "$key -> $attr->{$key}\n";
			$cat->setAttribute("$key2", "$attr->{$key2}");
			}
		}
		$data->appendChild($cat);
	}
	
	logAppend Dumper($refNouns,"\n") ;
	logAppend Dumper($ref,"\n");
	$status->setAttribute("status","0");
	$status->addText("OK");

}
1;
