#!/usr/bin/perl 
# Date: Nov. 5, 2013
# By  : yi zhang (yzhng@lab126.com)
# File: report_beautifier.pl
#       it take fixed format, and output data in nice and formatted way
use strict;
use Getopt::Std;
use List::Util qw(max);
#
# Options:
#   -c  : content, choice of (table, summary, all)
#         'table'   : output the table itself, this is default
#         'summary' : make an additional summary table based on given field count
#         'all'     : product the summary and original table, 
#                       summary will based on the given field count, 
#                       summary table will print before original table
#           for 'summary' and 'all', we need additional parameter 'f' 
#   -d  : field delimiter, default is '|'
#   -f  : field count. used with -c for value 'summary' and 'all'. this parameter used to tell when make summary table, which field to use
#   -i  : input file: required, no default 
#   -o  : output file: if not given, then output to terminal
#   -t  : output type: choice of (txt , html), default is txt
#
# Examples:
#    $0 -i result.txt
#        -- read 'result.txt', 
#            use '|' as field separator (default of '-d')
#            produce a text format (default of '-t' ) 
#            table based on original content (default of -c) 
#            to terminal (default of '-o')
#    $0 -i result.txt -d ';' -c all -f 1 -t html -o result.html
#        -- read 'result.txt', 
#            use ';' as field separator,
#            produce two tables: summary and original data
#            the summary will based on the 2nd field in table (count starts at 0)
#            and output it to  file named 'result.html'
#            in HTML format   

our %options=();
getopts("c:d:i:o:f:t:", \%options);

our $content     = $options{c};
our $delimiter   = $options{d};
our $summaryField= $options{f};
our $input       = $options{i};
our $output      = $options{o};
our $output_type = $options{t};
our @original_lines;
our @data;
our @spacing;
our $table="";
our %summary;
our $total;
our $summary_in_txt;
our $summary_in_html;

# check the options
parseOptions();
removeEmptyLines();
if ($content eq "summary"){
    computeSummary();
    if ($output_type eq "txt"){
        $table = make_summary_table_in_txt();
    }elsif ($output_type eq "html"){
        $table = make_summary_table_in_html();
    }else{
        # If previous logic are correct, Code will never hit this line
        print "\nERROR: Not supported output type [$output_type]";
        exit 1;
    }
}elsif ($content eq "table"){
    if ($output_type eq "txt" ){
        makePlaintextTable();
    }elsif ( $output_type eq "html" ){
        makeHTMLTable();
    }else{
        # If previous logic are correct, Code will never hit this line
        print "\nERROR: Not supported output type [$output_type]";
        exit 1;
    }
}elsif ($content eq "all"){
    computeSummary();
    my $summary_table = "";
    if ($output_type eq "txt"){
        $summary_table = make_summary_table_in_txt();
        makePlaintextTable();
    }elsif ($output_type eq "html"){
        $summary_table = make_summary_table_in_html();
        makeHTMLTable();
    }else{
        # If previous logic are correct, Code will never hit this line
        print "\nERROR: Not supported output type [$output_type]";
        exit 1;
    }
    $table = $summary_table ."\n". $table;
}else{
    # If previous logic are correct, Code will never hit this line
    print "\nERROR: Not supported content type [$content]";
    exit 1;
}

printTable();

#########################################################
#           subroutines                                 #
#########################################################
sub printTable {
    if ($output eq "terminal" ){
        print "$table\n";
    }else{
        print "Saved: $output\n";
        if (open (OUTPUT, ">$output")){
            print OUTPUT "$table\n";
            close OUTPUT;
        }else{
            print "Save Error: can not open output file [$output]";
            exit 1;
        }
    }
}

sub makeHTMLTable {
    $table = "\n<table border=1 class=spa>";
    $table .= makeHTMLHeaderRow();
    $table .= makeHTMLRow();
    $table .= "\n</table>";
}

sub makeHTMLHeaderRow {
    my $line = $data[0];
    my @fields = split(/\Q$delimiter/,$line);
    my $html = "\n<tr>";
    foreach my $field (@fields){
        $html .= "<th>$field</th>";
    }
    $html .= "</tr>";
    return $html;
}

sub makeHTMLRow {
    my $html = "";
    # start from 1, since the first line skipped -- the header
    foreach my $rowIndex (1..($#data+1)){
        my $line = $original_lines[$rowIndex];
        my @fields = split(/\Q$delimiter/,$line);
        $html .="\n<tr>";
        foreach my $field (@fields){
            $html .= "<td>$field</td>";
        }
        $html .= "</tr>";
    }
    return $html;
}

sub makePlaintextTable {
    updatePrintSpacing();
    makeBorderLine();
    makeOneLine($data[0]);
    makeBorderLine();
    foreach my $lineIndex (1..$#data){
        my $line = $data[$lineIndex];
        makeOneLine($line);
    }
    makeBorderLine();
}

sub makeBorderLine{
    if ($table eq ""){
        $table .= "+";
    }else{
        $table .= "\n+";
    }
    foreach my $length (@spacing){
        for my $i (0..($length-1)){
            $table .="-";
        }
        $table .="+";
    }
}

sub makeOneLine {
    my $line=shift;
    $table .= "\n";
    my @fields = split(/\Q$delimiter/,$line);
    for my $index (0..$#fields){
        my $value = $fields[$index];
        my $space = $spacing[$index];
        my $formatedLine = sprintf $delimiter."%-${space}s", $value;
        $table .= $formatedLine;
    }
    $table .= $delimiter;
}

sub removeEmptyLines {
    for my $line (@original_lines){
        next if ( $line =~ /^\s*$/ );
        chomp $line;
        push @data, $line;
    }
}

sub updatePrintSpacing {
    foreach my $line (@data){
        computeMaxLength ($line);
    }
}

sub computeMaxLength {
    my $line = shift;
    my @fields = split(/\Q$delimiter/,$line);
    for my $index (0..$#fields){
        # find the max lenth of each fields
        my $value = $fields[$index];
        my $length = length($value);
        if (! defined $spacing[$index]){
            $spacing[$index] = $length;
        }else{
            my $max_length = max($length,$spacing[$index]);
            $spacing[$index] = $max_length;
        } 
    }#foreach fields loop
}

sub computeSummary{
    foreach my $line (@data){
        $line =~ s/^\s+|\s+$//g;
        next if $line =~ /^#/;  # there is always a line 
        $total ++;
        my @fields = split(/\Q$delimiter/,$line);
        @fields = map { trim($_) }  @fields;
        #foreach (0..$#fields){
        #    print "\n--[".@fields[$_]."]";
        #}
        my $summarize_data = $fields [$summaryField];
        if ( exists $summary{$summarize_data}) {
            my $counter = $summary{$summarize_data};
            $counter ++;
            $summary{$summarize_data} = $counter; 
            #print " \nDebug: add 1 :[$summarize_data] = $counter";
        }else{
            $summary{$summarize_data} = 1;
            #print " \nDebug: add new :[$summarize_data] = 1";
        }
    }
}

sub make_summary_table_in_txt {
    my $text="";
    my $spacing=0;
    if ( (keys %summary) > 0 ){
        my @keys = keys %summary;
        $spacing = maxStringLength(@keys) + 2;
        # border line
        $text .= "\n" . summary_table_border_line($spacing);
        $text .= summary_table_content_line($spacing, "Total", 4, $total);
        $text .= "\n" . summary_table_border_line($spacing);
        foreach (sort keys %summary){
            my $category = $_;
            my $value    = $summary{$category};
            $text .= summary_table_content_line($spacing, $category, 4, $value);
            #$text .= "\n" . summary_table_border_line($spacing);
        }
    }
    $text .= "\n" . summary_table_border_line($spacing);
    return $text."\n";
}

sub summary_table_border_line(){
    my $spacing = shift;
    my $border = "+";
    for my $index (0..($spacing+1)){ $border .="-" }
    $border .= "+------+--------+";
    return $border;
}

sub summary_table_content_line{
    my ($spacing_category, $category, $spacing_value, $value)= @_;
    my $percent = sprintf ( "%.1f", 100 * ($value/$total) );
    my $formatted_line = sprintf(" %-${spacing_category}s | %${spacing_value}s | %5s% |",$category, $value, $percent);
    return "\n|". $formatted_line;
}

sub maxStringLength{
    my @array = @_;
    my $length = 0;
    for my $data (@array){
        my $len = length $data;
        $length = max ($length, $len);
    }
    return $length;
}

sub make_summary_table_in_html {
    my $html = "\n<Table border=1 class=spa>";
    $html .= "<tr><th>Total</th><th colspan=2>$total</th></tr>";
    for my $type (sort keys %summary){
        my $count = $summary{$type};
        my $percent = sprintf ( "%.1f", 100 * ($count/$total) );
        $html .= "\n<tr>";
        $html .= "<th>".$type."</th>";
        $html .= "<td>".$count."</td>";
        $html .= "<td>".$percent."% </td>";
        $html .="</tr>";
    }
    $html .= "\n</table>";
    return $html;
}

sub trim {
    my $str = shift;
    $str =~ s/^\s+|\s+$//g;
    return $str;
}

sub parseOptions {
    if (! defined $content ){
        $content = "table";
    }else{
        # when content type is 'summar' or 'all'
        if ( ( $content eq "summary") || ( $content eq "all" ) ){
            # -f is reqduired when content sets to 'summary' or 'all'
            if (! defined $summaryField ){
                print "\nfield count not given, can not make summary table, please use -f\n";
                usage();
                exit 1;
            }
        }else{
           if ($content ne "table"){
                print "\nUnknown content type '$content', please use 'table', 'summar', or 'all'";
                usage();
                exit 1;
            }
        }
    }
    if (! defined $delimiter){
        $delimiter="|";
    }elsif (length ($delimiter) != 1){
        print "\nError delimiter can only be one char";
        usage();
        exit 1;
    }
    if (! defined $input){
        print "Error: Input file is required\n";
        usage();
        exit 1;
    }else{
        if (open (INPUT, "<$input") ){
            @original_lines = <INPUT>;
            close INPUT;
        }else{
            print "Error: Can not read input file [$input]\n";
            usage();
            exit 1;
        }
    }
    if (! defined $output){
        $output = "terminal";
    }
    if (! defined $output_type){
        $output_type="txt";
    }else{
        if ( $output_type =~ /txt/i ){
            $output_type = "txt";
        }elsif ($output_type =~ /html/i) {
            $output_type = "html";
        }else{
            print "\nOutput type $output_type is not supported, default to 'txt'";
            $output_type="txt";
        }
    }
} #parseOptions

sub usage{
    print "\n=== Usage =:: $0 takes the following options
 Options:
   -c  : content, choice of (table, summary, all)
         'table'   : output the table itself, this is default
         'summary' : make an additional summary table based on given field count
         'all'     : product the summary and original table, 
                       summary will based on the given field count, 
                       summary table will print before original table
           for 'summary' and 'all', we need additional parameter 'f' 
   -d  : field delimiter, default is '|'
   -f  : field count. used with -c for value 'summary' and 'all'. this parameter used to tell when make summary table, which field to use
   -i  : input file: required, no default 
   -o  : output file: if not given, then output to terminal
   -t  : output type: choice of (txt , html), default is txt

 Examples:
    $0 -i result.txt
        -- read 'result.txt', 
            use '|' as field separator (default of '-d')
            produce a text format (default of '-t' ) 
            table based on original content (default of -c) 
            to terminal (default of '-o')
    $0 -i result.txt -d ';' -c all -f 1 -t html -o result.html
        -- read 'result.txt', 
            use ';' as field separator,
            produce two tables: summary and original data
            the summary will based on the 2nd field in table (count starts at 0)
            and output it to  file named 'result.html'
            in HTML format
";
}
