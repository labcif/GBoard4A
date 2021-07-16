/**
 * Module representing the directory detector and analysis logic for directories
 *
 * Authors: João Lourenço, Luís Ferreira
 * Copyright: João Lourenço (c) 2021
 *            Luís Ferreira (c) 2021
 * License: GPL-3.0
 */
module gboardforensics.analysis.dir;

import gboardforensics.gatherers;
import gboardforensics.analysis;

import std.file;
import std.path;

/**
 * This represents the directory auto detector logic to match a given gatherer
 */
struct DirDetector
{
	/**
	 * Constructs a directory detector with a given folder path
	 *
	 * Params:
	 *   path = path to the folder to be detected
	 */
	this(string path)
		in (path.exists())
		in (path.isDir())
	{
		this.dir = DirEntry(path);
	}

	/**
	 * Constructs a directory detector with a given directory entry
	 * Params:
	 *   dir = directory entry representing a folder to be detected
	 */
	this(DirEntry dir)
		in (dir.isDir())
	{
		this.dir = dir;
	}

	/**
	 * Detects the gatherer associated to the given folder
	 *
	 * Returns: the detected gatherer or null if not found
	 */
	IGatherer detect()
	{
		switch (dir.name.baseName())
		{
			case "translate_cache": return new TranslateCacheGatherer(dir);
			default: return null;
		}
	}

	private DirEntry dir;
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
