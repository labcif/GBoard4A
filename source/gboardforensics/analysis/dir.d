module gboardforensics.analysis.dir;

import gboardforensics.gatherers;
import gboardforensics.analysis;

import std.file;
import std.path;

struct DirDetector
{
	this(string path)
		in (path.exists())
		in (path.isDir())
	{
		this.dir = DirEntry(path);
	}

	this(DirEntry dir)
		in (dir.isDir())
	{
		this.dir = dir;
	}

	IGatherer detect()
	{
		switch (dir.name.baseName())
		{
			case "translate_cache": return new TranslateCacheGatherer(dir);
			default: return null;
		}
	}

	DirEntry dir;
}

/**
 * Dir analysis for each given dir
 *
 * Params:
 *   dirs = dirs to analyse
 * Returns: analysis report data
 */
AnalysisData dirAnalysis(string[] dirs)
{
	AnalysisData analysisData;

	foreach(dir; dirs)
		analysisData.add(DirDetector(dir).detect());

	return analysisData;
}
