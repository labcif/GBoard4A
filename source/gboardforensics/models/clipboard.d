module gboardforensics.models.clipboard;

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

	/// path to the dictionary
	immutable string path;
	/// list of dictionary entries
	Entry[] entries;
}
