use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::TaxonomyNode;
use Bio::EnsEMBL::DBSQL::TaxonomyDBAdaptor;
use Bio::EnsEMBL::DBSQL::TaxonomyNodeAdaptor;
use Bio::EnsEMBL::LookUp;

my $conf_file = 'db.conf';

my $conf = do $conf_file
  || die "Could not load configuration from " . $conf_file;

my $tconf = $conf->{tax};
$tconf->{db} = "ncbi_taxonomy";

my $dba =
  Bio::EnsEMBL::DBSQL::DBAdaptor->new( -user    => $tconf->{user},
									   -pass    => $tconf->{pass},
									   -dbname  => $tconf->{db},
									   -host    => $tconf->{host},
									   -port    => $tconf->{port},
									   -driver  => $tconf->{driver},
									   -group   => 'taxonomy',
									   -species => 'ena' );

my $node_adaptor = Bio::EnsEMBL::DBSQL::TaxonomyNodeAdaptor->new($dba);
ok( defined $node_adaptor, "Taxonomy Node Adaptor exists" );

my $helper = Bio::EnsEMBL::LookUp->new(-URL=>$conf->{ena_url},-NO_CACHE=>1);
ok( defined $helper, "Helper object exists" );

my $root = $node_adaptor->fetch_by_taxon_id($tconf->{taxon_id});
ok( defined $root, "Node ".$tconf->{taxon_id}." object exists" );

diag "Finding descendants for ".$tconf->{taxon_id};

my $dbas;
for my $node (@{$node_adaptor->fetch_descendants($root)}) {
	for my $dba (@{$helper->get_all_by_taxon_id($node->taxon_id())}) {
		diag "Found DBA for node ".$node->to_string();		
		push @$dbas, $dba;
	}
}

ok (defined $dbas && scalar(@$dbas)>0,"Found at least some DBAs");

done_testing;
