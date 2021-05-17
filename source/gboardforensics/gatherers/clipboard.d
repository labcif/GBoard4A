module gboardforensics.gatherers.clipboard;

import gboardforensics.gatherers;
import gboardforensics.models.clipboard;

import std.algorithm;
import std.file;
import std.array;

import d2sqlite3;

/**
 * This represents a gatherer for GBoard clipboard
 */
class ClipboardGatherer : IGatherer
{
	/**
	 * Constructs a gatherer with a given path
	 *
	 * Params:
	 *   path = path to the clipboard file
	 */
	this(string path)
		in(exists(path))
		in(isFile(path))
	{
		_clipboard.path = path;
	}

	///
	void gather()
	{
		auto db = Database(_clipboard.path);
		scope(exit) db.close();

		_clipboard.entries = db.execute(`SELECT
				text,
				html_text AS html,
				uri IS NULL OR uri = "" AS type,
				datetime(timestamp/1000, 'unixepoch') AS time,
				timestamp,
				uri
			FROM clips`)
			.map!(r => r.as!(Clipboard.Entry))
			.array;
	}

	/**
	 * Gets the collected clipboard
	 *
	 * Returns: clipboard data structure
	 */
	@property const(Clipboard) clipboard() const
	{
		return _clipboard;
	}

	private Clipboard _clipboard;
}
