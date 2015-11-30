# Copyright [2009-2014] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;

#my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('eg');
#my $gdba  = $multi->get_DBAdaptor('info');

my %args = ( -ENSEMBL_VERSION=>99,-EG_VERSION=>66,-DATE=>'2015-09-29' );
my $genome = Bio::EnsEMBL::MetaData::ReleaseInfo->new(%args);

ok( defined $genome, "Release object exists" );
ok( $genome->ensembl_version()                eq $args{-ENSEMBL_VERSION} );
ok( $genome->eg_version()             eq $args{-EG_VERSION} );
ok( $genome->date()         eq $args{-DATE} );

my $genome2 = Bio::EnsEMBL::MetaData::ReleaseInfo->new();
ok( defined $genome2, "Release object exists" );
ok( defined $genome2->ensembl_version() );
ok( !defined $genome2->eg_version() );
ok( defined $genome2->date() );

done_testing;