
=head1 LICENSE

Copyright [1999-2014] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

=pod

=head1 NAME

Bio::EnsEMBL::MetaData::DBSQL::GenomeInfoAdaptor

=head1 SYNOPSIS

my $gdba = Bio::EnsEMBL::MetaData::DBSQL::GenomeInfoAdaptor->build_adaptor();
my $md = $gdba->fetch_by_species("arabidopsis_thaliana");

=head1 DESCRIPTION

Adaptor for storing and retrieving GenomeInfo objects from MySQL genome_info database

To start working with an adaptor:

# getting an adaptor
## adaptor for latest public EG release
my $gdba = Bio::EnsEMBL::MetaData::DBSQL::GenomeInfoAdaptor->build_eg_adaptor();
## adaptor for specified public EG release
my $gdba = Bio::EnsEMBL::MetaData::DBSQL::GenomeInfoAdaptor->build_eg_adaptor(21);
## manually specify a given database
my $dbc = Bio::EnsEMBL::DBSQL::DBConnection->new(
-USER=>'anonymous',
-PORT=>4157,
-HOST=>'mysql-eg-publicsql.ebi.ac.uk',
-DBNAME=>'genome_info_21');
my $gdba = Bio::EnsEMBL::MetaData::DBSQL::GenomeInfoAdaptor->new(-DBC=>$dbc);

To find genomes, use the fetch methods e.g.

# find a genome by name
my $genome = $gdba->fetch_by_species('arabidopsis_thaliana');

# find and iterate over all genomes
for my $genome (@{$gdba->fetch_all()}) {
	print $genome->name()."\n";
}

# find and iterate over all genomes from plants
for my $genome (@{$gdba->fetch_all_by_division('EnsemblPlants')}) {
	print $genome->name()."\n";
}

# find and iterate over all genomes with variation
for my $genome (@{$gdba->fetch_all_with_variation()}) {
	print $genome->name()."\n";
}

# find all comparas for the division of interest
my $comparas = $gdba->fetch_all_compara_by_division('EnsemblPlants');

# find the peptide compara
my ($compara) = grep {$_->is_peptide_compara()} @$comparas;
print $compara->division()." ".$compara->method()."(".$compara->dbname().")\n";

# print out all the genomes in this compara
for my $genome (@{$compara->genomes()}) {
	print $genome->name()."\n";
}

=head1 Author

Dan Staines

=cut

package Bio::EnsEMBL::MetaData::DBSQL::DataReleaseInfoAdaptor;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::MetaData::DBSQL::BaseInfoAdaptor/;

use Carp qw(cluck croak);
use Bio::EnsEMBL::Utils::Argument qw( rearrange );
use Bio::EnsEMBL::MetaData::DataReleaseInfo;
use List::MoreUtils qw(natatime);

=head1 METHODS
=cut

sub store {
	my ( $self, $data_release ) = @_;
	if ( !defined $data_release->dbID() ) {
            # find out if organism exists first
            my $dbID;
            if(defined $data_release->ensembl_genomes_version()) {
                ($dbID) =
                    @{$self->dbc()->sql_helper()->execute_simple(
                          -SQL => "select data_release_id from data_release where ensembl_version=? and ensembl_genomes_version=?",
                          -PARAMS => [ $data_release->ensembl_version(), $data_release->ensembl_genomes_version() ] ) };
            } else {
                ($dbID) =
                    @{$self->dbc()->sql_helper()->execute_simple(
                          -SQL => "select data_release_id from data_release where ensembl_version=?",
                          -PARAMS => [ $data_release->ensembl_version() ] ) };
            }

            if ( defined $dbID ) {
                $data_release->dbID($dbID);
                $data_release->adaptor($self);
            }
	}
	if ( defined $data_release->dbID() ) {
            $self->update($data_release);
	} else {
		$self->dbc()->sql_helper()->execute_update(
                    -SQL =>q/insert into data_release(ensembl_version,ensembl_genomes_version,release_date,is_current) values (?,?,?,?)/,
                    -PARAMS => [ 
                         $data_release->ensembl_version(),
                         $data_release->ensembl_genomes_version(),
                         $data_release->release_date(),
                         $data_release->is_current()
                    ],
                    -CALLBACK => sub {
                        my ( $sth, $dbh, $rv ) = @_;
                        $data_release->dbID( $dbh->{mysql_insertid} );
                    } );
		$data_release->adaptor($self);
		$self->_store_cached_obj($data_release);
	}
	return;
} ## end sub store

sub update {
	my ( $self, $data_release ) = @_;
	if ( !defined $data_release->dbID() ) {
		croak "Cannot update an object that has not already been stored";
	}

	$self->dbc()->sql_helper()->execute_update(
		-SQL =>
q/update data_release set ensembl_version=?, ensembl_genomes_version=?, release_date=?, is_current=? where data_release_id=?/,
		-PARAMS => [ $data_release->ensembl_version(),
					 $data_release->ensembl_genomes_version(),
					 $data_release->release_date(),
					 $data_release->is_current(),
					 $data_release->dbID() ] );
	return;
}

=head2 _fetch_children
  Arg	     : Arrayref of Bio::EnsEMBL::MetaData::GenomeInfo
  Description: Fetch all children of specified genome info object
  Returntype : none
  Exceptions : none
  Caller     : internal
  Status     : Stable
=cut

sub _fetch_children {
	my ( $self, $md ) = @_;
	return;
}

my $base_data_release_fetch_sql =
q/select data_release_id as dbID, ensembl_version, ensembl_genomes_version, release_date, is_current from data_release/;

sub _get_base_sql {
	return $base_data_release_fetch_sql;
}

sub _get_id_field {
	return 'data_release_id';
}

sub _get_obj_class {
	return 'Bio::EnsEMBL::MetaData::DataReleaseInfo';
}

1;