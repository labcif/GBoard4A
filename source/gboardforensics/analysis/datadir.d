module gboardforensics.analysis.datadir;

import gboardforensics.analysis;
import gboardforensics.analysis.file;

import std.path;
import std.file;
import std.format;
import std.array;

/**
 * Performs a full GBoard analysis
 *
 * Params:
 *   dir = GBoard root directory
 *
 * Returns: gathered analysis data
 */
AnalysisData rootDirAnalysis(string dir)
{
	AnalysisData analysisData;
	analysisData.rootPath =
		asNormalizedPath(
			dir.isAbsolute ? dir : absolutePath(dir, getcwd())
		).array;

	  // ===========
	 // File caches
	// ===========

	static immutable filePaths = [
		buildPath("databases", DB.PersonalDictionary),
		buildPath("databases", DB.Trainingcache2),
		buildPath("databases", DB.Clipboard),
		buildPath("databases", DB.ExpressionHistory),
	];

	foreach(path; filePaths)
	{
		auto file = buildPath(dir, path);
		if(!exists(file)) continue;

		analysisData.add(FileDetector(file).detect());
	}

	  // ============
	 // Other caches
	// ============

	static immutable dirPaths = [
		buildPath("cache", "translate_cache"),
	];

	foreach(path; dirPaths)
	{
		auto d = buildPath(dir, path);
		if(!d.exists()) continue;

		analysisData.add(DirDetector(d).detect());
	}

	return analysisData;
}
