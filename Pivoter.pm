package Data::Pivoter;

use strict;
use vars qw($VERSION);    
$VERSION='0.07';

=head1 NAME

Data::Pivoter - Perl extension for pivot / cross tabulation of data

=cut


=head1 SYNOPSIS

$pivoter = Table::Pivoter->new(col=> <col>, row=> <row>, data=> <data>, 
                               group=> <group>, function=> <function>, 
                               donotvalidate=> <boolean>); 

$pivotedtableref = $pivoter->pivot(\@rawtable);

=cut

 
=head1 DESCRIPTION

A pivot object is created using new. Various parameters may be specified to 
alter how the table is pivoted. The actual pivot of a table is perfomed using the method pivot.

=cut


use vars '$AUTOLOAD';
 
use Data::Dumper;
use Carp;

my $debug = $ENV{PIVOTER_DEBUG};

=head1 Methods

=head2 new


Table::Pivoter->new(col=> <col>, row=> <row>, data=> <data>, 
group=> <group>, function=> <function>, numeric=> donotvalidate=> <boolean>); 

Creates a new pivoter object where <col> is the column containing data going
to be the column headings, <row> is the column going to row headings and 
<data> is the data column. <group> is a column used for higher level grouping,
i.e. splitting the data into different tables and {function} is a function to 
compile the data set for each row/col combination (Still not implemented)  If 
no function is given, the last value for each data point is returned. The
inputdata to new are validated to check that row,col, and data are defined and
that row and col differs. If this behaviour for some reason not is wanted,
donotvalidate can be set to a true value

Planned features (except for implementing the compilation function) includes to
add customizable sorting functions for rows and columns.

=cut



sub _validate{
  # Checks if a pivoter object is welldefined
  my $self=shift;
  # col, row and data must be defined
  my $validated = 
    defined $self->{_colhead} && 
      defined $self->{_rowhead} &&
	defined $self->{_data};
  # If all are defined, must check that row and column are different rows
  $validated = not($self->{_colhead} == $self->{_rowhead}) 
    if $validated;
  carp ("Definition error:
Col = $self->{_colhead}
Row = $self->{_rowhead}
Data= $self->{_data}\n") unless $validated;  
  return $validated;

}


sub _keysort{
  my $href = shift;
  my ($key,$i);
  foreach $key (sort {$a <=> $b} keys %$href){
    $href->{$key}=++$i;
  }
}


sub new{
  my $class = shift;
  my %para=@_;
  print "[C,R,D,G]:$para{col},$para{row},$para{data},$para{group}\n" if $debug;
  print "Don't validate\n" if $debug and $para{donotvalidate};
  print "Function: $para{function}\n" if $debug and $para{function};
  my $self = {
	      _colhead => $para{col},
	      _rowhead => $para{row},
	      _data    => $para{data},
	      _function=> $para{function},
	      _group   => $para{group},
	      _donotvalidate =>$para{donotvalidate},
	      _numeric => $para{numeric}
	     };
  print Dumper(\$self) if $debug>9;
  print "New[R,C]  : $self->{_rowhead},$self->{_colhead}\n" if $debug >3;
  bless $self,$class;
  $self->_validate unless $self->{_donotvalidate};
  return $self;
}

=head2 pivot

@pivotedtable = pivot (@rawtable);

The pivoter method actually performs the pivot with the parameters given in new
and returns the pivoted table. 

=cut



sub pivot{
  my $self = shift;
  my($table,$rows,$r,$c,$g,%rkeys,%ckeys,%gkeys,%hashtable,@pivot, @table);
  $table = shift; @table = @$table;
  print "Pivot[R,C]: $self->{_rowhead},$self->{_colhead}\n" if $debug > 3;
  for ($rows = 0;$rows < @table;$rows++){
    print "[\$rows: $rows]Pivot[R,C]: $self->{_rowhead},$self->{_colhead}\n" 
      if $debug > 3;
    print "row :>$table[$rows][$self->{_rowhead}]<\n" if $debug > 3;
    print "col :>$table[$rows][$self->{_colhead}]<\n" if $debug > 3;
    my $row = $table[$rows][$self->{_rowhead}];
    my $col = $table[$rows][$self->{_colhead}];
    my $group;
    # Collects and counts the row, col and group values
    $rkeys{$row}=++$r unless $rkeys{$row};
    $ckeys{$col}=++$c unless $ckeys{$col};
    if ($self->{_group}){  
      $group = $table[$rows][$self->{_group}];
      $gkeys{$group}=++$g unless $gkeys{$group};
    }
    my $ref;
    if (defined $group){
      $ref=\$hashtable{$row}{$col}{$group} 
    }else{
      $ref=\$hashtable{$row}{$col}
    }

    unless ($self->{_function}){
      # No function is defined, just picks up the value      
      $$ref=$table[$rows][$self->{_data}];
    }else{ 
      carp("Sorry, functions are still not working in Data::Pivoter...\n");
      push  @$ref, \$table[$rows][$self->{_data}];
      # Treats the $ref as an array reference and 
      # collects the data into that array to use the given function on them
      # after all the data have been collected.
    }
  }


  
  print "Rkeys presorted:\n",Dumper(\%rkeys) if $debug > 6;
  print "Ckeys presorted:\n",Dumper(\%ckeys) if $debug > 6;
  _keysort (\%rkeys);
  _keysort (\%ckeys);
  print "Rkeys sorted:\n",Dumper(\%rkeys) if $debug > 5;
  print "Ckeys sorted:\n",Dumper(\%ckeys) if $debug > 5;

  $c=1; # Puts in the row headers in the pivottable:
  foreach my $colkey (sort {$a<=>$b} keys %ckeys){
    $pivot[0][$c++] = $colkey;
  }
  # The row and col headers are in the first column and row
  foreach  my $rowkey (sort {$a <=> $b} keys %rkeys){
    # Puts in the col headers:
    $pivot[$rkeys{$rowkey}][0] = $rowkey;  
    foreach  my $colkey (sort {$a <=> $b} keys %ckeys){
      # Puts in the values in the finished table:
      $pivot[$rkeys{$rowkey}][$ckeys{$colkey}] = $hashtable{$rowkey}{$colkey};
    }
  }
  print '@pivot : ',Dumper(\@pivot) if $debug > 5;
  if ($self->{_function}){
    for ($r=1,@pivot,$r++){
      my $row=@pivot[$r];
      for ($c=1,@{$row},$c++){
	print "[$r,$c] @{$pivot[$r][$c]}" if $debug > 2;
	# eval{$pivot[$r][$c]= eval{$self->{_function}(@{$pivot[$r][$c]})}};
	eval{${$pivot[$r][$c]}=$self->{_function}};
      }
    }
    print "\n" if $debug >2;
  }

return \@pivot;
}


=head3 New algorithms

A possible enhancement is to use two different types of functions for
compilation, one which needs all the data avaliable to perform the calculation,
another that can can be applied to the data before all the datapoints are 
known, (e.g. to return the max value from the data set) to avoid going through 
the data set twice when possible

=cut

=head1 System variables

The variable PIVOTER_DEBUG may be set to get debugging output. A higher numerical
value gives more output.

=cut


=head1 Licencing

This module is distributed under the artistic licence, i.e. the same licence at Perl itself.

=cut

=head1 AUTHOR

Morten A.K. Sickel, Morten.Sickel@newmedia.no

=head1 SEE ALSO

perl(1).

=cut


1;
 
