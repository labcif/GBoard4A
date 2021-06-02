import std.stdio;
import std.file;
import std.path;
import core.stdc.errno;

import gboardforensics.analysis;
import gboardforensics.reporters;

import std.algorithm;
import std.file;
import std.range;
import std.typecons;

/**
 * Options passed to the program arguments
 */
@safe pure nothrow @nogc
struct Options {
	/// Output Type
	enum Type {
		json,
		html
	}

	string rootDir; /// Root directory
	string[] dirs; /// Directories
	string[] files; /// Files
	Type type; /// Output type
	string output; /// Ouput file path of the analysis report
	bool verbose; /// Print verbose information
}

int main(string[] args)
{
	AnalysisData analysisdata;
	Options opt;

	import std.getopt : getopt, defaultGetoptPrinter;
	auto helpInfo = getopt(
		args,
		"r|root-dir", "GBoard root directory analysis (must be used alone)", &opt.rootDir,
		"d|dir", "GBoard directory analysis", &opt.dirs,
		"f|file", "GBoard file analysis", &opt.files,
		"t|type", "Output format type (default: json)", &opt.type,
		"o|output", "Output file path of analysis report", &opt.output,
		"v|verbose", "Print extra information on the analysis", &opt.verbose
	);

	// if --help prompted
	if(helpInfo.helpWanted)
	{
		defaultGetoptPrinter(
			"Some information about the program\n",
			helpInfo.options
		);
		return 0;
	}

	// if --root-dir is specified it must be alone
	if (opt.rootDir.length && only(opt.dirs.length, opt.files.length).any!"a > 0")
	{
		defaultGetoptPrinter(
			"Cannot analyse multiple paths when --root-dir is specified!\n",
			helpInfo.options
		);
		return EINVAL;
	}

	// if none --root-dir, --dir, --file are specified
	if(!opt.rootDir.length && !only(opt.dirs.length, opt.files.length).any!"a > 0")
	{
		defaultGetoptPrinter(
			"Please specify a root path, a directory or a file!\n",
			helpInfo.options
		);
		return EINVAL;
	}

	// check if output folder exists
	if(opt.output && !opt.output.dirName().exists())
	{
		stderr.writefln!"The ouput folder specified '%s' does not exist!"(opt.output);
		return ENOENT;
	}

	if (opt.files.length && opt.files.any!(f => !f.exists()))
	{
		stderr.writefln!"One or more files specified [%-('%s', %)] do not exist!"(opt.files.filter!(f => !f.exists()));
		return ENOENT;
	}

	if (opt.dirs.length && opt.dirs.any!(d => !d.exists()))
	{
		stderr.writefln!"One or more directories specified [%-('%s', %)] do not exist!"(opt.dirs.filter!(d => !d.exists()));
		return ENOENT;
	}

	// run the analysis based on the passed arguments
	try {
		if (opt.rootDir)
			analysisdata = rootDirAnalysis(opt.rootDir);
		else
		{
			if (opt.files) analysisdata = fileAnalysis(opt.files);
			if (opt.dirs) analysisdata ~= dirAnalysis(opt.dirs);
		}

		/* generate the output report */
		Reporter reporter;
		final switch(opt.type) with(Options.Type)
		{
			case json: reporter = new JsonReporter(analysisdata); break;
			case html: reporter = new HTMLReporter(analysisdata); break;
		}

		auto outputString = reporter.toString();

		// if no --output argument specified, just print to stdout
		if(!opt.output) writeln(outputString);
		else std.file.write(opt.output, outputString);

	} catch(FailedAnalysisException e)
	{
		/*
		log errors occurred during the analysis
		TODO: this is a simple logging system. Could be improved by implementing
		a proper logging system. For now, it's ok to just write to stderr and
		exit with code > 0.
		*/
		stderr.writeln(e.msg);
		return 1;
	}

	return 0;
}
