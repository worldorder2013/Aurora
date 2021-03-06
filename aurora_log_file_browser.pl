#!/usr/bin/env perl


#############################################################################################
## This software can be used for personal and commercial use.                              ##
## Please do not remove this message when modifying and/or distributing this software.     ##
## I am not liable for any damage which occurs with the use of this software.              ##
## The main copy of this software is located at:                                           ##
##   https://github.com/worldorder2013/Aurora/blob/main/aurora_log_file_browser.pl         ##
## Any alterations from the main copy is solely at the other user's liabilities            ## 
## Author: Richmond Kerville Magallon                                                      ##
## Email me for questions, suggestions, and bugs at: hastyt627@gmail.com                   ##
#############################################################################################

use Tk 800.000;
use Tk::HList;
use Tk::LabEntry;
require Tk::DialogBox;
require Tk::Tree;
use strict;

## global variables
my %ERRORS;
my %WARNINGS;
my %MSG;
my $filename;
my $latest_file_pattern="*.log[0-9]*";

# GUI Tk starts here
my $top = MainWindow->new();
$top->title("Aurora Log File Browser");
$top->configure(-width => 300); 

## Menu GUI
#my $menu = $top->Menu;
$top->configure(-menu => my $menubar = $top->Menu); 
my $file = $menubar->cascade(-label => '~File', -tearoff=>0); 
my $edit = $menubar->cascade(-label => '~Edit', -tearoff=>0); 
my $help = $menubar->cascade(-label => '~Help', -tearoff=>0); 


my $newfile = $file->cascade(
	-label => 'Choose Tool',
	-underline => 0,
	-tearoff => 0
);
$file->separator;
$file->command(
	-label => 'Open',
	-underline => 0,
	-command => \&open_file
);
$file->command(
	-label => 'Open Latest',
	-underline => 0,
	-command => \&open_auto_log_file
);
$file->separator;
$file->command(
	-label => 'Save Messages (All)',
	-underline => 0,
	-command => [\&save_messages, "all"]
);
$file->command(
	-label => 'Save Messages (Summarized)',
	-underline => 0,
	-command => [\&save_messages, "summarized"]
);

my $tool = "innovus";

my $tools_ = [['Innovus', "innovus"], ['ICC2', "icc2"], ['Tempus', "tempus"]];

foreach (@$tools_){
	$newfile->radiobutton(
        	-label => $_->[0],
        	-variable => \$tool,
        	-value =>  $_->[1]
	);
}
#$newfile->radiobutton(
#	-label => "Innovus",
#	-variable => "$tool",
#	-value => "innovus"
#);
#$newfile->radiobutton(
#	-label => "ICC2",
#	-variable => "$tool",
#	-value => "icc2"
#);


$edit->command(-label => "'Latest File' Pattern", 
-command => \&open_dialog);


$help->command(-label => 'Aurora Log File Browser v1.0');
$help->command(-label => 'Author: RK*MaG');
my $fr = $top->Frame(-width => 1000, -height => 2000);
my $l = $fr->Label(-text => 'Log Browser', -anchor => 'n',
	-relief => 'groove',-width => 10, -height => '3');
my $l_bottom = $top->Label(-text => "No log file selected",
	-anchor => 'n', -relief => 'groove', -height => '3');


my $hlist = $top->Scrolled('Tree', -selectmode => 'extended', -indent => 10, -drawbranch => 1); 
## main Error header
$hlist->add("Errors", -text => "Errors"); 
## main Warning header
$hlist->add("Warnings", -text => "Warnings"); 
$hlist->add("Information", -text => "Info"); 
$hlist->configure(-width=>18);
$hlist->configure(-height=>30);
$hlist->configure(-command=>\&cb_populate_warning_error_textfield);
$hlist->configure(-browsecmd=>\&cb_multi_populate_warning_error_textfield);
$hlist->autosetmode();
## text Gui
my $text = $fr->Text(-background => 'white');
$text->configure(-height => 40);
$text->configure(-width => 150);
my $btn1 = $fr->Button(-text => 'Exit', -anchor=>'n', -command => sub {exit});

## Geometry management
#$l->pack(-side => "top");
$hlist->pack(-side=>'left', -anchor=>'n');
#$btn1->pack(-side=>"top", -expand=>1);
$text->pack(-side=>'right', -anchor=>'e', -fill=> 'x', -expand => 1);
$fr->pack(-expand => 1, -side=>'top', -anchor=>'w', -fill=>'x');
$l_bottom->pack(-side => "bottom", -fill=>'x');

## Main loop
MainLoop();


## Sub-routines
sub open_file {
	my $types = [
    	['log Files',       ['*.log*']],
    	['All Files',        '*',             ],
	];
	our $h=$top->getOpenFile(-filetypes=>$types);
	if ($h eq ""){
		return;	
	}else{
		&process_log_file($h);
	}
	
}
sub open_dialog{
	my $temp = $latest_file_pattern;
	my $dd=$top->DialogBox(-title=>"Enter Pattern", -buttons=>["OK", "Cancel"]);
	$dd->add('LabEntry', -textvariable => \$latest_file_pattern, -width=>20, -label=>"Pattern:",
	-labelPack => [-side => 'left'])->pack;
	my $mm = $dd->Show();
	if ($mm ne "OK"){
		$latest_file_pattern = $temp;
	}
}

sub open_auto_log_file {
	my @log_files=glob($latest_file_pattern);
	my $file_epoch;
	my $final_file = $log_files[0];
	my $file_epoch_max = (stat($log_files[0]))[9];
	foreach (@log_files){
		$file_epoch = (stat($_))[9];
		if ($file_epoch>=$file_epoch_max){
			$file_epoch_max = $file_epoch;
			$final_file = $_; 
		}
	}
	&process_log_file($final_file);

}

sub process_log_file {
	our $h = shift @_;
	our $mode = shift @_;
	&clear_hlist_entries;
	&clear_messages_variable;
	if ($tool eq "innovus"){
		&parse_error_warn_innovus($h);
	}
	&populate_hlist_entries;

	my $file_mod_time = localtime((stat($h))[9]);
	$l_bottom->configure(-text=>"$h $file_mod_time" );
}


sub parse_error_warn_innovus {
	$filename = shift @_;
	open(FH, "<$filename");
	# or die "Couldn't open file $filename: $!";
	while (<FH>) {
		chomp $_;
		if (/\*\*ERROR: \((\S+)\)/){
			push (@{$MSG{Errors}{$1}}, $_);
		}
		if (/\*\*WARN: \((\S+)\)/){
			push (@{$MSG{Warnings}{$1}}, $_);
		}
		if (/\*\* INFO: (.*)/){
			push (@{$MSG{Information}{"Info"}}, $_);
		}
	}
	close FH;
}

sub populate_hlist_entries {
	my $num_msg;
	foreach my $msgtype (keys %MSG) {
		foreach (sort keys %{$MSG{$msgtype}}){
			$num_msg = scalar( @{$MSG{$msgtype}{$_}});
			$hlist->add("${msgtype}.$_", -text => "$_ ($num_msg)"); 
		
		}
	} 
}

sub clear_hlist_entries {
	foreach ( keys %MSG){
		$hlist->delete('offsprings', $_) if $hlist->info('exists', $_);
	}
}
sub clear_messages_variable {
	%MSG=undef;
}

sub save_messages {
	my $mode = shift @_;
	our $h=$top->getSaveFile();
	open FH, ">$h";
	our $num_msg;
	foreach my $msgtype (keys %MSG) {
		next if $msgtype=~/^$/;
		print FH "------$msgtype------\n";
		foreach my $msgs ( keys %{$MSG{$msgtype}}){
			$num_msg = scalar( @{$MSG{$msgtype}{$msgs}});
			print FH "$msgs (Total of $num_msg):\n";
			
			if ($mode eq "all"){
				foreach my $lines (@{$MSG{$msgtype}{$msgs}}){
					print FH "$lines\n";
				}
			}elsif ($mode eq "summarized"){
				if ($msgs eq "Info"){
					my $sticky;
					foreach my $inf (sort {$a<=>$b} @{$MSG{$msgtype}{$msgs}}){
						if ($inf eq $sticky){
							next;
						}else{
							print FH "$inf\n";
							$sticky = $inf;
						}
					} 
				}else{
					print FH "$MSG{$msgtype}{$msgs}->[0]\n"; 
				}
			}
		
		}
		print FH "\n"; 
	}
	close FH;
}


sub waiver_filter {
return 0
}


sub cb_populate_warning_error_textfield {
	my ($widget , $mode) = @_;
	my ($msg_type, $msg_code) = split(/\./,$widget);
	$text->selectAll;
	$text->deleteSelected;
	if ( $msg_code eq ""){
		foreach (sort keys %{$MSG{$msg_type}}){
			$text->insert('end', "$_\n");
			$text->insert('end', "$MSG{$msg_type}{$_}->[0]\n");
			$text->insert('end', "\n");
		}
		return;
	}
	foreach ( @{$MSG{$msg_type}{$msg_code}}){
		$text->insert('end', "$_\n");
	}
}
sub cb_multi_populate_warning_error_textfield {
	my ($widget , $mode) = @_;
	$text->selectAll;
	$text->deleteSelected;
	foreach $widget ($hlist->info('selection')){
		my ($msg_type, $msg_code) = split(/\./,$widget);
		if ( $msg_code eq ""){
			foreach (sort keys %{$MSG{$msg_type}}){
				$text->insert('end', "$_\n");
			}
			next;
		}
		foreach ( @{$MSG{$msg_type}{$msg_code}}){
			$text->insert('end', "$_\n");
		}
	}
}
