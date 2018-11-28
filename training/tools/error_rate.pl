#!/usr/bin/perl

use strict;
use Algorithm::Diff qw(traverse_balanced);
use Getopt::Long;
use Data::Dumper;

my ($MER, $M2IN, $M2OUT, $ERROUT, $COROUT);

GetOptions(
    "mer=f" => \$MER,
    "m2in=s"  => \$M2IN,
    "m2out=s" => \$M2OUT,
    "errout=s" => \$ERROUT,
    "corout=s" => \$COROUT,
);

my @refs = getAnnotations($M2IN);
my @bv = map { 1 } 0 .. $#refs;
my @suf;

MERsuf(\@refs, \@suf);
my ($MTOT, $OTOT) = MERsum(\@suf, \@bv);
my $MERTOT = MER($MTOT, $OTOT);

my $DIR = $MER > $MERTOT ? 1 : -1;

my @diff = map { MER($MTOT - $_->[0], $OTOT - $_->[1]) - $MERTOT } @suf;
my @sorted = sort { ($diff[$b] <=> $diff[$a]) * $DIR } 0 .. $#bv;

#print Dumper([map { [$_, $diff[$_]] } @sorted]);

my $diff = $MER;
foreach my $i (@sorted) {
    $bv[$i] = 0;
    my $actMER = MER(MERsum(\@suf, \@bv));
    last if (($MER - $actMER) * $DIR < 0);
}

print STDERR MER(MERsum(\@suf, \@bv)), "\n";
print STDERR scalar grep { $_ != 0 } @bv;
print STDERR "\n";

printAll([getAnnotations2($M2IN)], \@bv, $M2OUT, $ERROUT, \@refs, $COROUT);

sub printAll {
    my ($refs, $bv, $m2, $err, $fullrefs, $cor) = @_;

    my $i = 0;
    my @restrefs = map { [ $refs->[$_->[1]], $fullrefs->[$_->[1]] ] } grep { $_->[0] == 1 } map { [$_, $i++] } @$bv; ;

    open(M2, ">$m2");
    open(ERR, ">$err");
    open(COR, ">$cor");
    foreach(@restrefs) {
        my $ref = $_->[0];
        my ($sent, $annot) = @$ref;
        my ($err, $cor) = @{$_->[1]};
        print M2 $sent, "\n";
        foreach my $a (@$annot) {
            print M2 $a, "\n";
        }
        print M2 "\n";

        #my $err = $sent;
        #$err =~ s/^S //g;
        $err =~ s/\\//g;
        print ERR $err, "\n";
        print COR $cor, "\n";
    }
    close(ERR);
    close(COR);
    close(M2);

}

sub MER {
    my ($M, $O) = @_;
    return $O/($M+$O);
}

sub MERsum {
    my $suf = shift;
    my $bv = shift;

    my $M = 0;
    my $O = 0;
    foreach my $i (0 .. $#$bv) {
        if ($bv->[$i] == 1) {
            $M += $suf->[$i]->[0];
            $O += $suf->[$i]->[1];
        }
    }
    return ($M, $O);
}

sub MERsuf {
    my ($refs, $suf) = @_;
    my ($M, $DIS) = (0, 0);
    foreach my $i (0 .. $#$refs) {
        my $min = 1;
        my ($minm, $mindis) = (0, 0);
        my ($orig, @corrected) = @{$refs->[$i]};

        my @stok;
        $orig =~ s/^\s+|\s+$//g;
        @stok = split(/\s/, $orig);

        foreach my $ref (@corrected) {
            my @rtok = split(/\s/, $ref);

            my ($m, $dis) = (0, 0);
            traverse_balanced(\@stok, \@rtok, {
               MATCH     => sub { $m++; },
               DISCARD_A => sub { $dis++; },
               DISCARD_B => sub { $dis++; },
               CHANGE    => sub { $dis++; }
            });

            my $mer = ($dis)/($m+$dis);
            if ($mer < $min) {
                ($minm, $mindis, $min) = ($m, $dis, $mer);
            }
        }
        $suf->[$i] = [$minm, $mindis];
    }
}

sub getAnnotations2 {
    my $refFile = shift;
    open(REF, "<$refFile") or die "Could not open $refFile\n";

    my @REFS;
    my @ANNOT;
    my $S;

    while(<REF>) {
        chomp;
        if(/^S\s/) {
            push(@REFS, [$S, [@ANNOT]]) if($S);
            $S = $_;
            @ANNOT = ();
        }
        if(/^A\s/) {
            push(@ANNOT, $_);
        }
    }
    close(REF);

    push(@REFS, [$S, [@ANNOT]]) if($S);
    return @REFS;
}

sub getAnnotations {
    my $refFile = shift;
    open(REF, "<$refFile") or die "Could not open $refFile\n";

    my @REFS;
    my @SENT;
    my $ORIG;
    my @ANNOT;
    my $ANNOT_NUM = 0;

    while(<REF>) {
        chomp;
        if(/^S\s/) {
            if(@SENT) {
                push(@REFS, [$ORIG, getSent($ORIG, \@SENT, \@ANNOT)]);
            }
            s/^S\s//;
            $ORIG = $_;
            @SENT = split(/\s/, $_);;
            @ANNOT = ();
        }
        if(/^A\s/) {
            s/^A\s//;
            my ($span, $type, $sub, $req, $none, $annotator) = split(/\|\|\|/, $_);

            if (not defined $ANNOT[$annotator]) {
                $ANNOT[$annotator] = [];
            }

            if ($ANNOT_NUM < $annotator) {
                $ANNOT_NUM = $annotator;
            }

            push($ANNOT[$annotator], [$span, $sub]);
        }
    }
    if(@SENT) {
        push(@REFS, [$ORIG, getSent($ORIG, \@SENT, \@ANNOT)]);
    }
    close(REF);

    # fill missing annotators with source sentence
    foreach (@REFS) {
        while (@$_ < $ANNOT_NUM + 2) {
            push(@$_, $_->[0]);
        }
    }

    return @REFS;
}

sub getSent {
    my ($source, $SENT, $ANNOT) = @_;

    my @OUT;
    foreach my $A (@$ANNOT) {
        my @sent = @$SENT;
        foreach my $a (@$A) {
            my ($span, $sub) = @$a;

            my ($start, $end) = split(/\s/, $span);
            next if ($start < 0 and $end < 0);

            for(my $i = $start; $i < $end; $i++) {
                if($sub and $i == $start) {
                    $sent[$i] = $sub;
                }
                else {
                    $sent[$i] = "\@DELETE ME\@";
                }
            }
            if($start == $end) {
                $sent[$start] = "$sub $sent[$start]";
            }
        }
        my @left = grep { !/^\@DELETE ME\@$/ } @sent;
        if(@left) {
            push(@OUT, join(" ",  @left));
        }
        else {
            push(@OUT, "");
        }
    }
    if (not @$ANNOT) {
        push(@OUT, $source);
    }

    #print Dumper([$SENT, $ANNOT, [@OUT]]);

    foreach (@OUT) {
        s/^\s+|\s+$//g;
    }

    return @OUT;
}
