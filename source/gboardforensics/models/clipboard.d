module gboardforensics.models.clipboard;

import gboardforensics.utils.serialization;
import asdf.serialization;

/**
 * This represents a clipboard data structure
 */
struct Clipboard
{
	/**
	 * This represents a single entry in the dictionary
	 */
	struct Entry
	{
		/**
		 * Entry Type
		 */
		enum Type
		{
			DOCUMENT,
			TEXT,
		}

		/// text
		@serdeIgnoreDefault string text;
		/// HTML text representation
		@serdeIgnoreDefault string html;
		/// type
		Type type;
		/// UNIX epoch formatted timestamp
		size_t timestamp;
		/// string representation of the timestamp
		string time;
		/// URI
		@serdeIgnoreDefault string uri;
	}

	/**
	 * Calculates the number of total clipboard entries
	 *
	 * Returns: number of total items
	 */
	@safe pure nothrow
	size_t countItems() const
	{
		return entries.length;
	}

	/// path to the dictionary
	immutable string path;
	/// list of dictionary entries
	SerializableArray!(const(Entry)) entries;
}

///
@safe pure nothrow
unittest
{
	Clipboard c;
	c.entries = new Clipboard.Entry[10];

	assert(c.countItems == 10);
}
