module gboardforensics.analysis.datadir;

import gboardforensics.analysis;
import gboardforensics.analysis.file;

import std.path;
import std.file;
import std.format;

/**
 * Performs a full data directory analysis
 *
 * Params:
 *   dir = GBoard data directory
 *
 * Returns: gathered analysis data
 */
AnalysisData dataDirAnalysis(string dir)
{
	AnalysisData analysisData;

	static immutable relativePaths = [
		"databases/"~DB.PersonalDictionary,
		"databases/"~DB.Trainingcache2,
	];

	foreach(path; relativePaths)
	{
		auto file = buildPath(dir, path);
		if(!exists(file)) continue;

		analysisData.add(FileDetector(file).detect());
	}

	return analysisData;
}