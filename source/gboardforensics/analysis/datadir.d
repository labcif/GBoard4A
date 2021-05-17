module gboardforensics.analysis.datadir;

import gboardforensics.analysis;
import gboardforensics.analysis.file;

import std.path;
import std.file;
import std.format;
import std.array;

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
	analysisData.path =
		asNormalizedPath(
			dir.isAbsolute ? dir : absolutePath(dir, getcwd())
		).array;

	static immutable relativePaths = [
		"databases/"~DB.PersonalDictionary,
		"databases/"~DB.Trainingcache2,
		"databases/"~DB.Clipboard,
	];

	foreach(path; relativePaths)
	{
		auto file = buildPath(dir, path);
		if(!exists(file)) continue;

		analysisData.add(FileDetector(file).detect());
	}

	return analysisData;
}
