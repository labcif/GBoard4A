import std.stdio;
import std.file;
import std.path;
import core.stdc.errno;

import gboardforensics.analysis;
import gboardforensics.analysis.file;
import gboardforensics.analysis.datadir;

/**
 * Options passed to the program arguments
 */
@safe pure nothrow @nogc
struct Options {
	string dataDir; /// Data directory to analyze
	string[] files; /// list of files to analyze
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
		"d|data-dir", "GBoard data directory to be analyzed", &opt.dataDir,
		"f|file", "GBoard single file analysis", &opt.files,
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

	// if --data-dir and --file both or none specified
	if((opt.dataDir && opt.files.length) || (!opt.dataDir && !opt.files.length))
	{
		defaultGetoptPrinter(
			"Please specify a data dir or a file!\n",
			helpInfo.options
		);
		return EINVAL;
	}

	// check if output folder exists
	if(opt.output && !exists(dirName(opt.output)))
	{
		stderr.writefln!"The ouput folder specified '%s' does not exist!"(opt.output);
		return ENOENT;
	}

	// run the analysis based on the passed arguments
	try {
		analysisdata = (opt.dataDir)
			? dataDirAnalysis(opt.dataDir)
			: fileAnalysis(opt.files);

		/*
		generate the output report
		TODO: this outputs a json report. For now, it's the only supported
		reporter but support could be added to report other formats.
		*/
		import gboardforensics.reporters.json : JsonReporter;
		auto prettyJson = new JsonReporter(analysisdata).toString();

		// if no --output argument specified, just print to stdout
		if(!opt.output) writeln(prettyJson);
		else std.file.write(opt.output, prettyJson);

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
