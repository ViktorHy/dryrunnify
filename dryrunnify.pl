#! /usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Long;
use File::Basename;


my %opt = ();
GetOptions( \%opt, 'main=s', 'help=s' );
my $main = $opt{main};
#my $snvfile = $opt{snv};


open (MAIN, $main) or die $!;
my %main;
my $process = 0;
my $filenames;
my @header;
my @when;
my @input;
my @output;
my @script;
my %sub;

my $block = "pre";
my $triple = 0;
my $files;
while(<MAIN>) {
    chomp;
    if( /(^process|input:|output:|script:|when:|shell:)/ ) {
        if( $1 eq "process" and $block ne "pre") {
            $files = parse_output(\%main);
            #print "$files\n";
            do_things(\%main, $files);
            $block = "pre";
            %main = ();
        }
        $block = $1;
        push @{$main{$block}}, $_ unless $triple;
    }
    elsif( /"""|'''/ ) {
        if( !$triple ) {
            $block = "script:";
            push @{$main{$block}}, '"""INSERTHERE"""';
        }
        if( $triple) {$triple = 0 } else {$triple = 1}

    }
    else {
        push @{$main{$block}}, $_ unless $triple;
    }
}

## Print last process
$files = parse_output(\%main);
do_things(\%main, $files);

sub do_things {
    my %data = %{$_[0]};
    my $triple = $_[1];

    for my $block ("pre", "process", "when:", "input:", "output:", "script:") {
        if( $data{$block}) {
            if( $block eq "script:") {
                my $index = parse_index(\@{$data{$block}});
                my $tmp = "";
                foreach (@$triple) {
                    $tmp = $tmp.$index.$_."\n";
                }
                $triple = $tmp;
                chomp $triple;
                for (my $i=0; $i<scalar(@{$data{$block}}); $i++ ) {
                    $data{$block}->[$i] =~ s/"""INSERTHERE"""/$index"""\n$triple\n$index"""/m;
                }
            }
            print join("\n", @{$data{$block}});
            print "\n";
        }
    }
}


sub parse_output {
    my %in = %{$_[0]};
    my @output = @{ $in{"output:"}} ;
    my $output = join("\n",@output);
    @output = split/,/,$output;
    my @files;
    foreach my $file (@output) {
       if ($file =~ /file\(\"(\S+)\"\)/) {
           push @files,"echo 'test' > $1";
       }
    }
    return \@files
}


sub parse_index {
    my $in = shift;
    my $R_curly = 0;
    my $L_curly = 0;
    my $index;
    foreach my $line (@$in) {
        if ($line =~ /\{/) {
            $L_curly++;
        }
        if ($line =~ /\}/) {
            $R_curly++;
        }
        if ($line =~ /INSERTHERE/) {
            if ($L_curly - $R_curly == 0) {
                ## No script block
                if ($L_curly == 0) {
                    $index = "\t";
                }
                ## Script block
                else {
                    $index = "\t\t";
                }
            }
            ## Codeblock within if/else bracket
            elsif ($L_curly - $R_curly == 1) {
                $index = "\t\t\t";
            }
        }
    }
    return $index;
}





# while (<MAIN>) {
#     chomp;
#     if (/^process/../^\s+$/) {
#        # print;
#         push @header,$_;
#     }
#     if (/input:/../^\s+$/) {
#         #print "INPUT:". $_;
#         push @input,$_;
#     }
#     if (/script:/../^\}/) {
#       #  print;
#         push @script,$_;
#     }
#     if (/when:/../^\s+$/) {
#       #  print;
#         push @when,$_;
#     }
#     if (/output:/../^\s+$/) {
#        # print;
#         push @output,$_;
#         #next if /output:/ || /^\s+$/;
#         #$filenames = parse_output($_);
#     }
#     my $count_commands = 0;
#     if (/^\}/) {
#         $process++;
#         $main{"$process"}{INPUT} = \@input;
#         print Dumper(\%main);
#         ##print "______________________\n";
#         #print @input,"\n\n";

#         @header = ();
#         #print @header,"\n\n";
#         #print Dumper(%sub);
#         @output = ();
#         @input = ();
#         @when = ();
#         @script = ();
#         %sub = ();
#         print "end_process\n";
#     }   
# }


