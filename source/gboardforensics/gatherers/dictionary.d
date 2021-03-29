module gboardforensics.gatherers.dictionary;

import gboardforensics.gatherers;
import gboardforensics.models.dictionary;

import std.algorithm;
import std.file;
import std.array;

import d2sqlite3;

/**
 * This represents a gatherer for GBoard personal dictionaries
 */
class DictionaryGatherer : IGatherer
{
	/**
	 * Constructs a gatherer with a given path
	 *
	 * Params:
	 *   path = path to the dictionary file
	 */
	this(string path)
		in(exists(path))
		in(isFile(path))
	{
		_dictionary.path = path;
	}

	///
	void gather()
	{
		auto db = Database(_dictionary.path);
		scope(exit) db.close();

		_dictionary.entries = db.execute("SELECT word, shortcut, locale FROM entry")
			.map!(r => r.as!(Dictionary.Entry))
			.array;
	}

	/**
	 * Gets the collected dictionary
	 *
	 * Returns: dictionary data structure
	 */
	@property const(Dictionary) dictionary() const
	{
		return _dictionary;
	}

	private Dictionary _dictionary;
}
