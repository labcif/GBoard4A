module gboardforensics.analysis.file;

import gboardforensics.gatherers;
import gboardforensics.gatherers.dictionary;
import gboardforensics.analysis;

import std.stdio;
import std.file;
import std.path : baseName;

import d2sqlite3;

/**
 * Represents a GBoard file detector. This struct detects and gets the right
 * file gatherer according to its filename and content.
 */
struct FileDetector
{

	/// SQLite3 database file signature
	private static immutable SQLITE3_SIGNATURE = [
		0x53, 0x51, 0x4C, 0x69, 0x74,
		0x65, 0x20, 0x66, 0x6F, 0x72,
		0x6D, 0x61, 0x74, 0x20, 0x33,
		0x00
	];

	/**
	 * Constructs a file detector using a file path
	 *
	 * Params:
	 *   path = path to the file to be detected
	 */
	public this(string path)
		in(exists(path))
		in(isFile(path))
	{
		this.file = File(path);
	}

	/**
	 * Constructs a file detector using an high-level file descriptor struct
	 *
	 * Params:
	 *   file = file instance to be detected
	 */
	public this(File file)
		in(file.isOpen)
	{
		this.file = file;
	}

	/**
	 * Detects the gatherer associated to the given file
	 *
	 * Returns: a gatherer if match a valid database, null if not found
	 */
	public IGatherer detect()
	{
		byte[] buf = file.rawRead(new byte[SQLITE3_SIGNATURE.length]);

		// detect SQLite3 file
		if(buf.length == SQLITE3_SIGNATURE.length && buf == SQLITE3_SIGNATURE)
		{
			// database scope
			{
				auto db = Database(file.name);
				scope(exit) db.close();

				// check if it has android_metadata table
				if(!detectAndroidTable(db)) return null;
			}

			// set position to the begining of the file
			file.seek(0, SEEK_SET);

			// detect file based on it's name
			switch(baseName(file.name))
			{
				case "PersonalDictionary.db": return new DictionaryGatherer(file.name);

				// no detection
				default: return null;
			}
		}

		// no detection
		return null;
	}

	/**
	 * Detects if the database is an android database
	 *
	 * Params:
	 *   db = database instance
	 *
	 * Returns: true if database has android_metadata table, false otherwise
	 */
	private bool detectAndroidTable(Database db)
	{
		import std.algorithm.iteration : map;
		import std.array : array;

		return !db.execute("SELECT name FROM sqlite_master
			WHERE LOWER(type) IN ('table','view')
			AND LOWER(name) = 'android_metadata'")
			.empty;
	}

	/// high-level file descriptor struct representing the file to be detected
	private File file;
}

/**
 * Performs a file analysis for each given file
 *
 * Params:
 *   files = given files to analyse
 * Returns: the analysis report data
 */
AnalysisData fileAnalysis(string[] files)
{
	AnalysisData analysisData;

	foreach(file; files)
		analysisData.add(FileDetector(file).detect());

	return analysisData;
}
